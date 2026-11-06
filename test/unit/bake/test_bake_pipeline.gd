## Test suite for BakePipeline.
## Covers: default step wiring, custom step replacement, execution order,
## fatal-error stopping, can_run_with_errors stopping and context passthrough.
extends GdUnitTestSuite


const DEFAULT_STEP_IDS: Array[StringName] = [
	&"collect_brushes",
	&"init_semantic_data",
	&"bake_semantic_layer",
	&"post_process",
	&"validate",
	&"build_runtime_room",
	&"apply_default_theme",
	&"save_room_data",
]


class MockBakeStep:
	extends BakeStep

	var id: StringName = &""
	var run_count: int = 0
	var can_run: bool = true
	var fatal_message: String = ""
	var execution_log: Array[StringName] = []

	func get_id() -> StringName:
		return id

	func run(context: RoomBakeContext) -> RoomBakeContext:
		run_count += 1
		execution_log.append(id)
		if not fatal_message.is_empty():
			context.report.add_error(
				BakeIssue.new(
					BakeIssue.IssueType.BAKE_FAILED,
					BakeIssue.Severity.FATAL,
					fatal_message,
					Vector2i.ZERO
				)
			)
		return context

	func can_run_with_errors() -> bool:
		return can_run


func _make_step(
	step_id: StringName,
	execution_log: Array[StringName],
	can_run: bool = true
) -> MockBakeStep:
	var step := MockBakeStep.new()
	step.id = step_id
	step.execution_log = execution_log
	step.can_run = can_run
	return step


func _make_context() -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.report = BakeReport.new()
	return context


func test_default_constructor_creates_expected_steps_in_order() -> void:
	var pipeline := BakePipeline.new()
	var step_ids: Array[StringName] = []
	for step in pipeline._steps:
		step_ids.append(step.get_id())

	assert_array(step_ids).contains_exactly(DEFAULT_STEP_IDS)


func test_custom_steps_replace_defaults() -> void:
	var execution_log: Array[StringName] = []
	var step1 := _make_step(&"step1", execution_log)
	var step2 := _make_step(&"step2", execution_log)

	var pipeline := BakePipeline.new([step1, step2])

	assert_int(pipeline._steps.size()).is_equal(2)
	assert_object(pipeline._steps[0]).is_equal(step1)
	assert_object(pipeline._steps[1]).is_equal(step2)


func test_run_executes_steps_in_order() -> void:
	var execution_log: Array[StringName] = []
	var step1 := _make_step(&"step1", execution_log)
	var step2 := _make_step(&"step2", execution_log)
	var step3 := _make_step(&"step3", execution_log)

	var pipeline := BakePipeline.new([step1, step2, step3])
	pipeline.run(_make_context())

	assert_array(execution_log).contains_exactly([&"step1", &"step2", &"step3"])


func test_fatal_issue_stops_pipeline() -> void:
	var execution_log: Array[StringName] = []
	var step1 := _make_step(&"step1", execution_log)
	var step2 := _make_step(&"step2", execution_log)
	step2.fatal_message = "Fatal error"
	var step3 := _make_step(&"step3", execution_log)

	var pipeline := BakePipeline.new([step1, step2, step3])
	pipeline.run(_make_context())

	assert_int(step1.run_count).is_equal(1)
	assert_int(step2.run_count).is_equal(1)
	assert_int(step3.run_count).is_zero()


func test_step_that_cannot_run_with_errors_stops_pipeline_before_execution() -> void:
	var execution_log: Array[StringName] = []
	var step1 := _make_step(&"step1", execution_log)
	var step2 := _make_step(&"step2", execution_log, false)
	var step3 := _make_step(&"step3", execution_log)

	var pipeline := BakePipeline.new([step1, step2, step3])
	pipeline.run(_make_context())

	assert_int(step1.run_count).is_equal(1)
	assert_int(step2.run_count).is_zero()
	assert_int(step3.run_count).is_zero()


func test_run_returns_same_context_instance() -> void:
	var execution_log: Array[StringName] = []
	var pipeline := BakePipeline.new([_make_step(&"step", execution_log)])
	var context := _make_context()

	var returned_context := pipeline.run(context)

	assert_object(returned_context).is_equal(context)


func test_default_registry_wires_processors() -> void:
	var pipeline := BakePipeline.new()

	# The registry is created internally; verify it by checking the bake_semantic_layer step
	# has a registry with the expected brush types.
	var bake_semantic_step: BakeSemanticLayerStep = null
	for step in pipeline._steps:
		if step is BakeSemanticLayerStep:
			bake_semantic_step = step
			break

	assert_object(bake_semantic_step).is_not_null()
	assert_object(bake_semantic_step._registry).is_not_null()

	var registry: BakeProcessorRegistry = bake_semantic_step._registry
	var types: Array[SemanticBrush.BrushType] = registry.get_types()

	assert_int(types.size()).is_equal(3)
	assert_bool(types.has(SemanticBrush.BrushType.PLATFORM)).is_true()
	assert_bool(types.has(SemanticBrush.BrushType.WALL)).is_true()
	assert_bool(types.has(SemanticBrush.BrushType.BACKGROUND)).is_true()

	# Verify each registered processor is the correct type
	assert_object(registry.get_processor(SemanticBrush.BrushType.PLATFORM)).is_class(&"PlatformBakeProcessor")
	assert_object(registry.get_processor(SemanticBrush.BrushType.WALL)).is_class(&"WallBakeProcessor")
	assert_object(registry.get_processor(SemanticBrush.BrushType.BACKGROUND)).is_class(&"BackgroundBakeProcessor")
