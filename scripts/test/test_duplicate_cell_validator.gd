## DuplicateCellValidator unit tests.
## Covers: duplicate platform/wall/background cells; exact issue type and position.
extends GdUnitTestSuite


func _make_context_with_platforms(positions: Array[Vector2i]) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	var cells: Array[SemanticSpatialCell] = []
	for pos in positions:
		var cell = SemanticSpatialCell.new()
		cell.cell = pos
		cells.append(cell)
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)
	return context


func _make_context_with_walls(positions: Array[Vector2i]) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	var cells: Array[SemanticSpatialCell] = []
	for pos in positions:
		var cell = SemanticSpatialCell.new()
		cell.cell = pos
		cells.append(cell)
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, cells)
	return context


func _make_context_with_backgrounds(positions: Array[Vector2i]) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	var cells: Array[SemanticSpatialCell] = []
	for pos in positions:
		var cell = SemanticSpatialCell.new()
		cell.cell = pos
		cells.append(cell)
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.BACKGROUND, cells)
	return context


func test_no_duplicates_passes() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_duplicate_platform_cell_reports_error() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()
	assert_bool(context.report.is_has_saverity(BakeIssue.Severity.ERROR)).is_true()


func test_duplicate_wall_cell_reports_error() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [Vector2i(3, 3), Vector2i(3, 3)]
	var context = _make_context_with_walls(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_duplicate_background_cell_reports_error() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [Vector2i(1, 2), Vector2i(1, 2)]
	var context = _make_context_with_backgrounds(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_duplicate_issue_has_overlap_type() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	var all = context.report.get_all_issues()
	assert_bool(all.has(BakeIssue.IssueType.BRUSH_OVERLAP)).is_true()


func test_duplicate_issue_stores_position() -> void:
	var validator = DuplicateCellValidator.new()
	var dup_pos = Vector2i(5, 7)
	var positions: Array[Vector2i] = [dup_pos, dup_pos]
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	var all = context.report.get_all_issues()
	var overlap_issues = all[BakeIssue.IssueType.BRUSH_OVERLAP]
	assert_array(overlap_issues).is_not_empty()
	assert_vector(overlap_issues[0].position).is_equal(dup_pos)


func test_unique_cells_no_error() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)
	]
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_empty_layer_passes() -> void:
	var validator = DuplicateCellValidator.new()
	var positions: Array[Vector2i] = []
	var context = _make_context_with_platforms(positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()
