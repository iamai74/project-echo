## Base bake and build class tests.
## Covers: BakeStep, BuildStep, BakeProcessor, BakeValidator, PostBakeProcessor
## base-class contracts, identifiers, default behaviour.
extends GdUnitTestSuite

# ── BakeStep ──────────────────────────────────────────────────────

func test_bake_step_returns_empty_id() -> void:
	var step = BakeStep.new()
	assert_str(step.get_id()).is_empty()

func test_bake_step_returns_empty_display_name() -> void:
	var step = BakeStep.new()
	assert_str(step.get_display_name()).is_empty()

func test_bake_step_default_run_returns_same_context() -> void:
	var step = BakeStep.new()
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	var returned = step.run(context)
	assert_object(returned).is_equal(context)

func test_bake_step_default_can_run_with_errors_is_true() -> void:
	var step = BakeStep.new()
	assert_bool(step.can_run_with_errors()).is_true()

# ── BuildStep (theme) ────────────────────────────────────────────

func test_build_step_returns_empty_id() -> void:
	var step = BuildStep.new()
	assert_str(step.get_id()).is_empty()

func test_build_step_returns_empty_display_name() -> void:
	var step = BuildStep.new()
	assert_str(step.get_display_name()).is_empty()

func test_build_step_default_run_returns_same_context() -> void:
	var step = BuildStep.new()
	var context = ThemeBuildContext.new()
	context.report = ThemeBuildReport.new()
	var returned = step.run(context)
	assert_object(returned).is_equal(context)

func test_build_step_default_can_run_with_errors_is_true() -> void:
	var step = BuildStep.new()
	assert_bool(step.can_run_with_errors()).is_true()

# ── BakeProcessor ────────────────────────────────────────────────

func test_bake_processor_execute_does_nothing_by_default() -> void:
	var processor = BakeProcessor.new()
	var semantic_room = SemanticRoomData.new()
	var brushes: Array[SemanticBrush] = []
	# Default execute is a pass; it should not throw or emit signals.
	processor.execute(brushes, semantic_room)

# ── BakeValidator ────────────────────────────────────────────────

func test_bake_validator_validate_does_nothing_by_default() -> void:
	var validator = BakeValidator.new()
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	# Default validate is a pass; no issues should be added.
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()

# ── PostBakeProcessor ───────────────────────────────────────────

func test_post_bake_processor_execute_returns_empty() -> void:
	var processor = PostBakeProcessor.new()
	var result = processor.execute([])
	assert_int(result.size()).is_zero()

func test_post_bake_processor_execute_returns_empty_with_cells() -> void:
	var processor = PostBakeProcessor.new()
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(0, 0)
	var cells: Array[SemanticSpatialCell] = [cell]
	var result = processor.execute(cells)
	assert_int(result.size()).is_zero()
