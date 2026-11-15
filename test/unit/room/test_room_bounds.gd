## RoomBounds unit tests.
## Covers: origin/size construction, empty/invalid area, negative origins,
## cell and rectangle containment, empty playable air and geometry independence.
extends GdUnitTestSuite


func _cell(x: int, y: int) -> SemanticSpatialCell:
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(x, y)
	return cell


# --- Construction ---

func test_from_origin_and_size_preserves_values() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(3, 4), Vector2i(10, 8))
	assert_int(bounds.position.x).is_equal(3)
	assert_int(bounds.position.y).is_equal(4)
	assert_int(bounds.size.x).is_equal(10)
	assert_int(bounds.size.y).is_equal(8)


# --- has_area ---

func test_has_area_true_for_positive_dimensions() -> void:
	assert_bool(RoomBounds.has_area(Rect2i(0, 0, 1, 1))).is_true()
	assert_bool(RoomBounds.has_area(Rect2i(-5, -6, 4, 9))).is_true()


func test_has_area_false_for_empty_or_zero_size() -> void:
	assert_bool(RoomBounds.has_area(Rect2i(0, 0, 0, 0))).is_false()
	assert_bool(RoomBounds.has_area(Rect2i(0, 0, 5, 0))).is_false()
	assert_bool(RoomBounds.has_area(Rect2i(0, 0, 0, 5))).is_false()


# --- Negative origin ---

func test_negative_origin_kept_with_correct_size() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(-4, -6), Vector2i(8, 10))
	assert_int(bounds.position.x).is_equal(-4)
	assert_int(bounds.position.y).is_equal(-6)
	assert_int(bounds.size.x).is_equal(8)
	assert_int(bounds.size.y).is_equal(10)
	assert_bool(RoomBounds.has_area(bounds)).is_true()


func test_contains_cell_respects_negative_origin() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(-4, -6), Vector2i(8, 10))
	# end is (-4+8, -6+10) = (4, 4); last inside cell is (3, 3).
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(-4, -6))).is_true()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(3, 3))).is_true()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(4, 3))).is_false()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(3, 4))).is_false()


# --- contains_cell at each edge ---

func test_contains_cell_at_edges() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(10, 8))
	# Corners and the last inside cell are contained.
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(0, 0))).is_true()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(9, 7))).is_true()
	# One cell outside on every edge is not contained.
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(10, 0))).is_false()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(-1, 0))).is_false()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(0, 8))).is_false()
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(0, -1))).is_false()


func test_contains_cell_in_empty_bounds_is_false() -> void:
	assert_bool(RoomBounds.contains_cell(Rect2i(), Vector2i(0, 0))).is_false()


# --- contains_rect at each edge ---

func test_contains_rect_fully_inside() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(10, 8))
	# Strictly inside and touching every boundary edge (end == bounds.end).
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(1, 1, 2, 2))).is_true()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(0, 0, 10, 8))).is_true()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(0, 1, 3, 2))).is_true()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(7, 0, 3, 8))).is_true()


func test_contains_rect_crossing_an_edge_is_false() -> void:
	var bounds = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(10, 8))
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(9, 0, 3, 8))).is_false()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(0, -1, 10, 8))).is_false()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(0, 7, 10, 3))).is_false()
	assert_bool(RoomBounds.contains_rect(bounds, Rect2i(-1, 0, 2, 8))).is_false()


func test_contains_rect_in_empty_bounds_is_false() -> void:
	assert_bool(RoomBounds.contains_rect(Rect2i(), Rect2i(0, 0, 1, 1))).is_false()


# --- Empty playable air ---

func test_empty_playable_air_still_contains_cell() -> void:
	# A logical room with no geometry still contains its playable cells.
	var bounds = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(12, 10))
	assert_bool(RoomBounds.contains_cell(bounds, Vector2i(6, 5))).is_true()


func test_marker_in_empty_air_inside_room_outside_geometry() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [
		_cell(2, 9), _cell(3, 9), _cell(4, 9),
	])

	var room_bounds = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(12, 10))
	var geometry = GeometryBounds.compute(layers)

	var marker = Vector2i(6, 3)
	# The marker is in the authored playable area...
	assert_bool(RoomBounds.contains_cell(room_bounds, marker)).is_true()
	# ...yet it sits in air, outside the occupied geometry extent.
	var in_geometry = (
		marker.x >= geometry.position.x and marker.x < geometry.end.x and
		marker.y >= geometry.position.y and marker.y < geometry.end.y
	)
	assert_bool(in_geometry).is_false()


# --- Geometry independence ---

func test_room_bounds_unchanged_by_geometry() -> void:
	var authored = RoomBounds.from_origin_and_size(Vector2i(0, 0), Vector2i(12, 10))

	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [ _cell(1, 1), _cell(2, 2) ])
	layers.add_cells(SpatialLayer.SpatialType.WALL, [ _cell(5, 5) ])

	# Geometry bounds derive from the cells...
	var geometry = GeometryBounds.compute(layers)
	assert_int(geometry.position.x).is_equal(1)
	assert_int(geometry.size.x).is_equal(5)

	# ...but the logical room rectangle ignores the cells entirely.
	assert_int(authored.position.x).is_equal(0)
	assert_int(authored.size.x).is_equal(12)
	assert_int(authored.size.y).is_equal(10)
