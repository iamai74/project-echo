## ValidateStep unit tests.
## Covers: all validators run, errors accumulate in the report,
## step metadata, the default validator list, and that the step does not skip validators.
extends GdUnitTestSuite


# --- Step metadata ---

func test_get_id_returns_validate() -> void:
	var step = ValidateStep.new()
	assert_str(step.get_id()).is_equal(&"validate")


func test_get_display_name_returns_string() -> void:
	var step = ValidateStep.new()
	assert_str(step.get_display_name()).is_not_empty()


# --- Validator access ---

func test_get_validators_returns_the_default_validators() -> void:
	var validators := ValidateStep.new().get_validators()

	assert_array(validators).has_size(4)
	assert_object(validators[0]).is_instanceof(DuplicateCellValidator)
	assert_object(validators[1]).is_instanceof(SemanticOverlapValidator)
	assert_object(validators[2]).is_instanceof(TopologyValidator)
	assert_object(validators[3]).is_instanceof(SemanticCellValidator)


# --- Validators run ---

func test_run_invokes_all_validators() -> void:
	var v1: BakeValidator = mock(BakeValidator)
	var v2: BakeValidator = mock(BakeValidator)
	var v3: BakeValidator = mock(BakeValidator)
	var v4: BakeValidator = mock(BakeValidator)

	var context = _make_minimal_context()

	var validators: Array[BakeValidator] = [v1, v2, v3, v4]
	var step := ValidateStep.new(validators)

	var result = step.run(context)

	verify(v1, 1).validate(context)
	verify(v2, 1).validate(context)
	verify(v3, 1).validate(context)
	verify(v4, 1).validate(context)
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
