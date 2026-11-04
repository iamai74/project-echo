## BakeSemanticLayerStep unit tests.
## Covers: step metadata, processor execution for each registered type,
## issue signal forwarding to the bake report, and empty-brush handling.
extends GdUnitTestSuite


# --- Mock processor that records calls and optionally emits issues ---
class MockBakeProcessor:
	extends BakeProcessor
	var execute_called: bool = false
	var execute_brushes: Array = []
	var execute_context: Variant = null
	var _emit_issue: bool = false
	var _issue_message: String = ""

	func set_emit_issue(p_emit: bool, p_message: String = "test_issue") -> void:
		_emit_issue = p_emit
		_issue_message = p_message

	func execute(brushes: Array[SemanticBrush], semantic_room: SemanticRoomData) -> void:
		execute_called = true
		execute_brushes = brushes
		execute_context = semantic_room
		if _emit_issue:
			var issue = BakeIssue.new(
				BakeIssue.IssueType.BRUSH_OVERLAP,
				BakeIssue.Severity.ERROR,
				_issue_message,
				Vector2i.ZERO
			)
			issue_found.emit(issue)


# --- Step metadata ---

func test_get_id_returns_bake_semantic_layer() -> void:
	var registry = BakeProcessorRegistry.new()
	var step = BakeSemanticLayerStep.new(registry)
	assert_str(step.get_id()).is_equal(&"bake_semantic_layer")


func test_get_display_name_returns_string() -> void:
	var registry = BakeProcessorRegistry.new()
	var step = BakeSemanticLayerStep.new(registry)
	assert_str(step.get_display_name()).is_not_empty()


# --- Processor execution ---

func test_run_calls_processor_for_each_registered_type() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_platform = MockBakeProcessor.new()
	var mock_wall = MockBakeProcessor.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_platform)
	registry.register(SemanticBrush.BrushType.WALL, mock_wall)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	step.run(context)

	assert_bool(mock_platform.execute_called).is_true()
	assert_bool(mock_wall.execute_called).is_true()


func test_run_passes_brushes_and_semantic_data_to_processor() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_platform = MockBakeProcessor.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_platform)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	step.run(context)

	assert_bool(mock_platform.execute_called).is_true()
	assert_object(mock_platform.execute_context).is_equal(context.semantic_data)
	# brushes array is empty because context has no brushes
	assert_int(mock_platform.execute_brushes.size()).is_zero()


func test_run_passes_no_brushes_when_collection_is_empty() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_processor = MockBakeProcessor.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_processor)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	step.run(context)

	assert_int(mock_processor.execute_brushes.size()).is_zero()


func test_run_skips_unregistered_types() -> void:
	var registry = BakeProcessorRegistry.new()
	# Only PLATFORM registered
	var mock_platform = MockBakeProcessor.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_platform)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	# WALL brushes exist in context but no WALL processor registered
	step.run(context)

	assert_bool(mock_platform.execute_called).is_true()


# --- Issue forwarding ---

func test_run_forwards_processor_issues_to_report() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_processor = MockBakeProcessor.new()
	mock_processor.set_emit_issue(true, "overlap at cell")
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_processor)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	step.run(context)

	assert_bool(context.report.is_has_issues()).is_true()


func test_run_accumulates_issues_from_multiple_processors() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_platform = MockBakeProcessor.new()
	mock_platform.set_emit_issue(true, "platform overlap")
	var mock_wall = MockBakeProcessor.new()
	mock_wall.set_emit_issue(true, "wall overlap")
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_platform)
	registry.register(SemanticBrush.BrushType.WALL, mock_wall)

	var step = BakeSemanticLayerStep.new(registry)
	var context = _make_minimal_context()

	step.run(context)

	var all_issues = context.report.get_all_issues()
	assert_bool(all_issues.size() > 0).is_true()


# --- Context helpers ---

func _make_minimal_context() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.brushes = BrushCollection.new()
	return context
