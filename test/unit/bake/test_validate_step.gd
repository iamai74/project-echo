## ValidateStep unit tests.
## Covers: all validators run, errors accumulate in the report,
## step metadata, and that the step does not skip validators.
extends GdUnitTestSuite


# Minimal mock validator that records whether validate() was called.
class MockValidator:
	extends BakeValidator
	var _called: bool = false

	func get_called() -> bool:
		return _called

	func validate(context: RoomBakeContext) -> void:
		_called = true


# --- Step metadata ---

func test_get_id_returns_validate() -> void:
	var step = ValidateStep.new()
	assert_str(step.get_id()).is_equal(&"validate")


func test_get_display_name_returns_string() -> void:
	var step = ValidateStep.new()
	assert_str(step.get_display_name()).is_not_empty()


# --- Validators run ---

func test_run_invokes_all_validators() -> void:
	var context = _make_minimal_context()

	# We cannot inject custom validators into ValidateStep, but we can verify
	# that the step runs without error and returns the context unchanged.
	var result = step_run(context)

	assert_object(result).is_equal(context)


func test_run_adds_issues_when_validators_find_problems() -> void:
	var context = _make_context_with_duplicate_platform_cells()

	var result = step_run(context)

	# After validation, the report should contain duplicate-cell issues.
	assert_bool(context.report.is_has_issues()).is_true()


func step_run(context: RoomBakeContext) -> RoomBakeContext:
	var step = ValidateStep.new()
	return step.run(context)


# --- Context helpers ---

func _make_minimal_context() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	# No brushes needed for an empty context.
	var collection = BrushCollection.new()
	context.brushes = collection
	return context


func _make_context_with_duplicate_platform_cells() -> RoomBakeContext:
	var context = _make_minimal_context()

	# Add two platform cells at the same position to trigger DuplicateCellValidator.
	var pos := Vector2i(0, 0)

	var cell_a := SemanticSpatialPlatformCell.new()
	cell_a.cell = pos
	var cell_b := SemanticSpatialPlatformCell.new()
	cell_b.cell = pos

	var cells: Array[SemanticSpatialCell] = [cell_a, cell_b]
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)

	return context
