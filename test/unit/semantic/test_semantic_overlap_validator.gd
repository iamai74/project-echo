## SemanticOverlapValidator unit tests.
## Covers: platform/wall overlap, non-overlap, issue location.
extends GdUnitTestSuite


func _make_context_with_platforms_and_walls(
	platform_positions: Array[Vector2i], wall_positions: Array[Vector2i]
) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()

	var platform_cells: Array[SemanticSpatialCell] = []
	for pos in platform_positions:
		var cell = SemanticSpatialCell.new()
		cell.cell = pos
		platform_cells.append(cell)
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	var wall_cells: Array[SemanticSpatialCell] = []
	for pos in wall_positions:
		var cell = SemanticSpatialCell.new()
		cell.cell = pos
		wall_cells.append(cell)
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, wall_cells)

	return context


func test_no_overlap_passes() -> void:
	var validator = SemanticOverlapValidator.new()
	var context = _make_context_with_platforms_and_walls(
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(2, 0), Vector2i(3, 0)]
	)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_overlap_reports_error() -> void:
	var validator = SemanticOverlapValidator.new()
	var overlap_pos = Vector2i(5, 5)
	var context = _make_context_with_platforms_and_walls(
		[overlap_pos, Vector2i(0, 0)],
		[overlap_pos, Vector2i(1, 1)]
	)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()
	assert_bool(context.report.is_has_saverity(BakeIssue.Severity.ERROR)).is_true()


func test_overlap_issue_type_is_brush_overlap() -> void:
	var validator = SemanticOverlapValidator.new()
	var overlap_pos = Vector2i(3, 3)
	var context = _make_context_with_platforms_and_walls([overlap_pos], [overlap_pos])
	validator.validate(context)
	var all = context.report.get_all_issues()
	assert_bool(all.has(BakeIssue.IssueType.BRUSH_OVERLAP)).is_true()


func test_overlap_issue_stores_position() -> void:
	var validator = SemanticOverlapValidator.new()
	var overlap_pos = Vector2i(7, 2)
	var context = _make_context_with_platforms_and_walls([overlap_pos], [overlap_pos])
	validator.validate(context)
	var all = context.report.get_all_issues()
	var overlap_issues = all[BakeIssue.IssueType.BRUSH_OVERLAP]
	assert_array(overlap_issues).is_not_empty()
	assert_vector(overlap_issues[0].position).is_equal(overlap_pos)


func test_empty_layer_passes(platform_positions: Array[Vector2i], wall_positions: Array[Vector2i], _test_parameters := [
	[ [], [Vector2i(0, 0), Vector2i(1, 0)] ],
	[ [Vector2i(0, 0), Vector2i(1, 0)], [] ]
]) -> void:
	var validator = SemanticOverlapValidator.new()
	var context = _make_context_with_platforms_and_walls(platform_positions, wall_positions)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_multiple_overlaps_each_reported() -> void:
	var validator = SemanticOverlapValidator.new()
	var context = _make_context_with_platforms_and_walls(
		[Vector2i(0, 0), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 1)]
	)
	validator.validate(context)
	var all = context.report.get_all_issues()
	var overlap_issues = all.get(BakeIssue.IssueType.BRUSH_OVERLAP, [])
	assert_int(overlap_issues.size()).is_greater_equal(2)
