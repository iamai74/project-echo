## ConnectionPointValidator unit tests.
## Covers: a valid opening on each side, an invalid side, a zero or negative
## size, a wrong orientation on every side, a rectangle outside the bounds,
## a rectangle that touches the wrong edge, openings that cover a wall or
## platform cell, openings that cover a background or marker (both allowed),
## empty logical bounds, negative-origin bounds, an empty and a duplicate id,
## overlapping and adjacent rectangles, invalid-size rectangles excluded from
## the overlap check, and that validation never mutates the input connections.
extends GdUnitTestSuite


const BOUNDS := Rect2i(Vector2i.ZERO, Vector2i(10, 10))


# --- Helpers ---


func _make_context(bounds: Rect2i = BOUNDS) -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.room_bounds = bounds
	context.brushes = BrushCollection.new()
	return context


func _add_connection(
	context: RoomBakeContext,
	side: ConnectionSide.Value,
	position: Vector2i,
	connection_id: StringName = &"conn",
	size: Vector2i = Vector2i.ONE,
) -> ConnectionData:
	var connection := ConnectionData.new()
	connection.id = connection_id
	connection.side = side
	connection.position = position
	connection.size = size
	context.semantic_data.connections.append(connection)
	return connection


func _add_wall(context: RoomBakeContext, position: Vector2i) -> void:
	var cell := SemanticSpatialCell.new()
	cell.cell = position
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, [cell])


func _add_platform(context: RoomBakeContext, position: Vector2i) -> void:
	var cell := SemanticSpatialCell.new()
	cell.cell = position
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, [cell])


func _add_background(context: RoomBakeContext, position: Vector2i) -> void:
	var cell := SemanticSpatialCell.new()
	cell.cell = position
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.BACKGROUND, [cell])


func _add_marker(
	context: RoomBakeContext,
	type: MarkerType.Value,
	position: Vector2i,
	content_id: StringName = &"content",
) -> MarkerData:
	var marker := MarkerData.new()
	marker.type = type
	marker.position = position
	marker.content_id = content_id
	context.semantic_data.markers.add_marker(type, marker)
	return marker


func _validate(context: RoomBakeContext) -> void:
	ConnectionPointValidator.new().validate(context)


func _issues(context: RoomBakeContext, type: BakeIssue.IssueType) -> Array:
	return context.report.get_all_issues().get(type, [])


# --- A valid opening on every side produces no issue ---


func test_valid_openings_on_every_side_produce_no_issue() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"top", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.BOTTOM, Vector2i(2, 9), &"bottom", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.LEFT, Vector2i(0, 2), &"left", Vector2i(1, 3))
	_add_connection(context, ConnectionSide.Value.RIGHT, Vector2i(9, 2), &"right", Vector2i(1, 3))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- An out-of-range side is an error ---


func test_invalid_side_produces_error() -> void:
	var context := _make_context()
	var connection := ConnectionData.new()
	connection.side = 99
	connection.position = Vector2i(2, 0)
	connection.size = Vector2i(3, 1)
	connection.id = &"bad_side"
	context.semantic_data.connections.append(connection)

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("99")
	assert_str(issues[0].message).contains("invalid side")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(2, 0))


# --- A zero or negative size is an error ---


func test_zero_size_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"zero", Vector2i(0, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid size")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


func test_negative_size_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.LEFT, Vector2i(0, 2), &"negative", Vector2i(1, -1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid size")


# --- A wrong orientation is an error ---


func test_wrong_orientation_vertical_produces_error() -> void:
	var context := _make_context()
	# A TOP opening must be one cell tall.
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"too_tall", Vector2i(3, 2))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid orientation")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


func test_wrong_orientation_horizontal_produces_error() -> void:
	var context := _make_context()
	# A LEFT opening must be one cell wide.
	_add_connection(context, ConnectionSide.Value.LEFT, Vector2i(0, 2), &"too_wide", Vector2i(2, 3))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid orientation")


func test_bottom_opening_with_wrong_orientation_produces_error() -> void:
	var context := _make_context()
	# A BOTTOM opening must be one cell tall, placed on the bottom row.
	_add_connection(context, ConnectionSide.Value.BOTTOM, Vector2i(2, 8), &"too_tall", Vector2i(3, 2))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid orientation")
	assert_vector(issues[0].position).is_equal(Vector2i(2, 8))


func test_right_opening_with_wrong_orientation_produces_error() -> void:
	var context := _make_context()
	# A RIGHT opening must be one cell wide, placed on the right column.
	_add_connection(context, ConnectionSide.Value.RIGHT, Vector2i(8, 2), &"too_wide", Vector2i(2, 3))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid orientation")
	assert_vector(issues[0].position).is_equal(Vector2i(8, 2))


# --- A rectangle outside the bounds is an error ---


func test_outside_bounds_produces_error() -> void:
	var context := _make_context()
	# A BOTTOM opening placed just past the bottom edge.
	_add_connection(context, ConnectionSide.Value.BOTTOM, Vector2i(2, 10), &"out", Vector2i(3, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("outside logical room bounds")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(2, 10))


# --- A negative room origin is handled like any other origin ---


func test_negative_origin_bounds_accept_top_opening() -> void:
	var context := _make_context(Rect2i(-5, -5, 10, 10))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(-5, -5), &"main_exit", Vector2i(3, 1))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- A rectangle that touches the wrong edge is an error ---


func test_touches_wrong_edge_produces_error() -> void:
	var context := _make_context()
	# A LEFT opening that does not reach the left edge.
	_add_connection(context, ConnectionSide.Value.LEFT, Vector2i(3, 2), &"off_edge", Vector2i(1, 3))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("does not touch")
	assert_str(issues[0].message).contains("left room edge")
	assert_vector(issues[0].position).is_equal(Vector2i(3, 2))


func test_right_opening_away_from_edge_produces_error() -> void:
	var context := _make_context()
	# A RIGHT opening that does not reach the right edge.
	_add_connection(context, ConnectionSide.Value.RIGHT, Vector2i(8, 2), &"off_edge", Vector2i(1, 3))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("does not touch")
	assert_str(issues[0].message).contains("right room edge")
	assert_vector(issues[0].position).is_equal(Vector2i(8, 2))


# --- An opening that covers a wall or platform cell is an error ---


func test_opening_contains_wall_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"main_exit", Vector2i(3, 1))
	_add_wall(context, Vector2i(3, 0))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("overlaps")
	assert_str(issues[0].message).contains("wall cell")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(2, 0))


func test_opening_contains_platform_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"main_exit", Vector2i(3, 1))
	_add_platform(context, Vector2i(3, 0))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("overlaps")
	assert_str(issues[0].message).contains("platform cell")


# --- A background cell or a marker inside an opening is allowed ---


func test_opening_contains_background_produces_no_issue() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"main_exit", Vector2i(3, 1))
	_add_background(context, Vector2i(3, 0))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


func test_marker_inside_opening_produces_no_issue() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(3, 0), &"main_exit", Vector2i(1, 1))
	_add_marker(context, MarkerType.Value.ENEMY_SPAWN, Vector2i(3, 0), &"enemy_1")

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Empty logical bounds are an error, not a crash ---


func test_empty_bounds_produce_error() -> void:
	var context := _make_context(Rect2i())
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(5, 5), &"conn", Vector2i(1, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("invalid or empty")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


# --- An empty or duplicate id is an error ---


func test_empty_id_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"", Vector2i(1, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("empty id")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


func test_duplicate_id_produces_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"shared", Vector2i(1, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(5, 0), &"shared", Vector2i(1, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("duplicate id")
	assert_vector(issues[0].position).is_equal(Vector2i(5, 0))


# --- Overlapping rectangles are an error; adjacent ones are allowed ---


func test_overlapping_rectangles_produce_error() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"top_00", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(3, 0), &"top_01", Vector2i(3, 1))

	_validate(context)

	var issues := _issues(context, BakeIssue.IssueType.BRUSH_OVERLAP)
	assert_int(issues.size()).is_equal(1)
	assert_str(issues[0].message).contains("overlaps connection")
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)
	assert_vector(issues[0].position).is_equal(Vector2i(2, 0))


# --- Overlap messages fall back to the position when an id is missing ---


func test_overlap_with_empty_ids_reports_position_identity() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(3, 0), &"", Vector2i(3, 1))

	_validate(context)

	var overlap := _issues(context, BakeIssue.IssueType.BRUSH_OVERLAP)
	assert_int(overlap.size()).is_equal(1)
	assert_str(overlap[0].message).contains("(2, 0) overlaps connection (3, 0)")


# --- Openings with an invalid size are left out of the pairwise overlap check ---


func test_invalid_size_rectangles_produce_no_overlap_issue() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"empty_a", Vector2i(0, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"valid_c", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"empty_b", Vector2i(0, 1))

	_validate(context)

	assert_int(_issues(context, BakeIssue.IssueType.BRUSH_OVERLAP).size()).is_equal(0)
	assert_int(_issues(context, BakeIssue.IssueType.SEMANTIC_CONFLICT).size()).is_equal(2)


# --- A missing semantic data model is ignored, not a crash ---


func test_null_semantic_data_produces_no_issue() -> void:
	var context := RoomBakeContext.new()
	context.report = BakeReport.new()

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


func test_adjacent_rectangles_produce_no_issue() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"adj_a", Vector2i(2, 1))
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(4, 0), &"adj_b", Vector2i(2, 1))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Different sides near the same corner are allowed when rectangles do not overlap ---


func test_corner_meeting_sides_produce_no_issue() -> void:
	var context := _make_context()
	# A TOP opening and a RIGHT opening near the top-right corner.
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(8, 0), &"top_exit", Vector2i(1, 1))
	_add_connection(context, ConnectionSide.Value.RIGHT, Vector2i(9, 1), &"right_exit", Vector2i(1, 1))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Validation does not mutate the input connections ---


func test_no_mutation() -> void:
	var context := _make_context()
	_add_connection(context, ConnectionSide.Value.TOP, Vector2i(2, 0), &"top", Vector2i(3, 1))
	_add_connection(context, ConnectionSide.Value.BOTTOM, Vector2i(5, 12), &"bottom", Vector2i(2, 2))
	_add_connection(context, ConnectionSide.Value.LEFT, Vector2i(0, 0), &"", Vector2i(1, 1))

	var snapshot_before := _snapshot(context)
	_validate(context)
	var snapshot_after := _snapshot(context)

	assert_int(context.semantic_data.connections.size()).is_equal(3)
	assert_array(snapshot_after).is_equal(snapshot_before)


func _snapshot(context: RoomBakeContext) -> Array:
	var snapshot: Array = []
	for connection in context.semantic_data.connections:
		snapshot.append(String(connection.id))
		snapshot.append(connection.side)
		snapshot.append(connection.position.x)
		snapshot.append(connection.position.y)
		snapshot.append(connection.size.x)
		snapshot.append(connection.size.y)
	return snapshot
