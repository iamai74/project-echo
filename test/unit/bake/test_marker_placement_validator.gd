## MarkerPlacementValidator unit tests.
## Covers: a valid marker, an invalid type (including that other problems are
## still reported), an empty content_id, a duplicate and an empty marker_id,
## a position outside the bounds, empty bounds, a position inside a wall,
## a duplicate type and position, cross-type sharing at one cell, a marker
## sitting on a platform, a marker brush that is not 1x1, negative-origin
## bounds, and that validation never mutates the input markers.
extends GdUnitTestSuite


const TILE_SIZE := 32
const BOUNDS := Rect2i(Vector2i.ZERO, Vector2i(10, 10))


# --- Helpers ---


func _make_context(bounds: Rect2i = BOUNDS) -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.room_bounds = bounds
	context.brushes = BrushCollection.new()
	return context


func _add_marker(
	context: RoomBakeContext,
	type: MarkerType.Value,
	position: Vector2i,
	content_id: StringName = &"content",
	marker_id: StringName = &"",
) -> MarkerData:
	var marker := MarkerData.new()
	marker.type = type
	marker.position = position
	marker.content_id = content_id
	marker.marker_id = marker_id
	context.semantic_data.markers.add_marker(type, marker)
	return marker


func _validate(context: RoomBakeContext) -> void:
	MarkerPlacementValidator.new().validate(context)


func _issues(context: RoomBakeContext, type: BakeIssue.IssueType) -> Array:
	return context.report.get_all_issues().get(type, [])


# --- A valid marker produces no issue ---


func test_valid_marker_produces_no_issue() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"enemy_1", &"m1")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- An invalid type is an error ---


func test_invalid_type_produces_error() -> void:
	var context := _make_context()
	var marker := MarkerData.new()
	marker.type = 99
	marker.position = Vector2i(3, 3)
	marker.content_id = &"content"
	context.semantic_data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, marker)

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("99")
	assert_str(issues[0].message).contains("invalid type")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(3, 3))


func test_invalid_type_still_reports_other_problems() -> void:
	var context := _make_context()
	var invalid := MarkerData.new()
	invalid.type = 99
	invalid.position = Vector2i(1, 1)
	invalid.content_id = &"content"
	invalid.marker_id = &"shared"
	context.semantic_data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, invalid)
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"content", &"shared")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(2)
	assert_str(issues[0].message).contains("invalid type")
	assert_str(issues[1].message).contains("duplicate marker_id")


# --- An empty content_id is an error ---


func test_empty_content_id_produces_error() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"", &"m1")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("empty content_id")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


# --- A duplicate marker_id is an error; an empty marker_id is allowed ---


func test_duplicate_marker_id_produces_error() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"a", &"shared")
	_add_marker(context, MarkerType.Value.LOOT_SPAWN, Vector2i(6, 6), &"b", &"shared")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("duplicate marker_id")
	assert_str(issues[0].message).contains("shared")
	assert_vector(issues[0].position).is_equal(Vector2i(6, 6))


func test_empty_marker_id_produces_no_issue() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"a", &"")
	_add_marker(context, MarkerType.Value.LOOT_SPAWN, Vector2i(6, 6), &"b", &"")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- A position outside the bounds is an error ---


func test_position_outside_bounds_produces_error() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(100, 100), &"content")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("outside logical room bounds")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(100, 100))


# --- Negative room origin is handled like any other origin ---


func test_negative_origin_bounds_accept_inside_marker() -> void:
	var context := _make_context(Rect2i(-5, -5, 10, 10))
	_add_marker(context, MarkerType.Value.CHECKPOINT, Vector2i(-5, -5), &"checkpoint_1")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


func test_negative_origin_bounds_reject_outside_marker() -> void:
	var context := _make_context(Rect2i(-5, -5, 10, 10))
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(5, 0), &"enemy_1")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("outside logical room bounds")
	assert_vector(issues[0].position).is_equal(Vector2i(5, 0))


# --- Empty bounds produce one error per marker ---


func test_empty_bounds_produce_error_per_marker() -> void:
	var context := _make_context(Rect2i())
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(5, 5), &"content")
	_add_marker(context, MarkerType.Value.LOOT_SPAWN, Vector2i(6, 6), &"content")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(2)
	assert_str(issues[0].message).contains("invalid or empty")
	assert_str(issues[1].message).contains("invalid or empty")


# --- A position inside a wall is an error ---


func test_position_inside_wall_produces_error() -> void:
	var context := _make_context()
	var wall_cell := SemanticSpatialCell.new()
	wall_cell.cell = Vector2i(3, 3)
	var wall_cells: Array[SemanticSpatialCell] = [wall_cell]
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, wall_cells)
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"content")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("wall")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(3, 3))


# --- A duplicate type and position is an overlap error ---


func test_duplicate_type_and_position_produces_error() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"a", &"m1")
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"b", &"m2")

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.BRUSH_OVERLAP)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("duplicate type and position")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(3, 3))


# --- Different marker types may share one cell ---


func test_different_types_at_one_cell_produce_no_issue() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"a", &"m1")
	_add_marker(context, MarkerType.Value.LOOT_SPAWN, Vector2i(3, 3), &"b", &"m2")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- A marker on a platform or background cell is allowed ---


func test_marker_on_platform_produces_no_issue() -> void:
	var context := _make_context()
	var platform_cell := SemanticSpatialPlatformCell.new()
	platform_cell.cell = Vector2i(3, 3)
	var platform_cells: Array[SemanticSpatialCell] = [platform_cell]
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"content")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- A marker brush that is not 1x1 is an error ---


func test_marker_brush_not_1x1_produces_error() -> void:
	var context := _make_context()
	var brush = auto_free(MarkerBrush.new())
	brush.size = Vector2i(2, 2)
	context.brushes.add_brush(brush)

	var valid_brush = auto_free(MarkerBrush.new())
	valid_brush.size = Vector2i.ONE
	context.brushes.add_brush(valid_brush)

	var disabled_brush = auto_free(MarkerBrush.new())
	disabled_brush.size = Vector2i(2, 2)
	disabled_brush.enabled = false
	context.brushes.add_brush(disabled_brush)

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("not 1x1")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


# --- A missing semantic data model is ignored, not a crash ---


func test_null_semantic_data_produces_no_issue() -> void:
	var context := RoomBakeContext.new()
	context.report = BakeReport.new()

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Validation does not mutate the input markers ---


func test_no_mutation() -> void:
	var context := _make_context()
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"content_a", &"id_a")
	_add_marker(context, MarkerType.Value.LOOT_SPAWN, Vector2i(6, 6), &"content_b", &"id_b")
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 3), &"content_c", &"id_c")

	var snapshot_before := _snapshot(context)
	_validate(context)
	var snapshot_after := _snapshot(context)

	assert_int(context.semantic_data.markers.get_all_markers().size()).is_equal(3)
	assert_array(snapshot_after).is_equal(snapshot_before)


func _snapshot(context: RoomBakeContext) -> Array:
	var snapshot: Array = []
	for marker in context.semantic_data.markers.get_all_markers():
		snapshot.append(marker.type)
		snapshot.append(marker.position.x)
		snapshot.append(marker.position.y)
		snapshot.append(String(marker.content_id))
		snapshot.append(String(marker.marker_id))
	return snapshot
