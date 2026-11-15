## RoomDataBuilder unit tests.
## Covers: platform/wall/background cell conversion, room_bounds copy, geometry_bounds
## computation, marker and connection sorting/duplication/empty-input handling, version
## 2 output and version 1 compatibility loading, topology cell data extraction, missing
## topology fallback.
extends GdUnitTestSuite


func _make_cell(position: Vector2i) -> SemanticSpatialCell:
	var cell = SemanticSpatialCell.new()
	cell.cell = position
	return cell


func _make_topology_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value
) -> SemanticSpatialTopologyCell:
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = position
	var topo = SpatialTopology.new()
	topo.shape = shape
	topo.corner = corner
	cell.topology = topo
	return cell


func _make_semantic_data() -> SemanticRoomData:
	return SemanticRoomData.new()


func _make_marker(
	type: MarkerType.Value, position: Vector2i, marker_id: StringName, content_id: StringName
) -> MarkerData:
	var marker = MarkerData.new()
	marker.type = type
	marker.position = position
	marker.marker_id = marker_id
	marker.content_id = content_id
	return marker


func _make_connection(
	side: ConnectionSide.Value, position: Vector2i, connection_id: StringName, size: Vector2i = Vector2i.ONE
) -> ConnectionData:
	var connection = ConnectionData.new()
	connection.side = side
	connection.position = position
	connection.id = connection_id
	connection.size = size
	return connection


# --- Basic conversion ---

func test_build_converts_platform_cells() -> void:
	var data = _make_semantic_data()
	var platform_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.ALL),
		_make_topology_cell(Vector2i(1, 0), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_object(result).is_not_null()
	assert_int(result.platforms.size()).is_equal(2)
	assert_int(result.platforms[0].shape).is_equal(CellShape.Value.SINGLE)
	assert_int(result.platforms[0].corners).is_equal(CellCorner.Value.ALL)
	assert_int(result.platforms[1].shape).is_equal(CellShape.Value.SINGLE)
	assert_int(result.platforms[1].corners).is_equal(CellCorner.Value.NO)


func test_build_converts_wall_cells() -> void:
	var data = _make_semantic_data()
	var wall_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 5), CellShape.Value.SINGLE, CellCorner.Value.ALL),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, wall_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_int(result.walls.size()).is_equal(1)
	assert_int(result.walls[0].shape).is_equal(CellShape.Value.SINGLE)


func test_build_converts_background_cells() -> void:
	var data = _make_semantic_data()
	var bg_cells: Array[SemanticSpatialCell] = [
		_make_cell(Vector2i(0, 0)),
		_make_cell(Vector2i(1, 0)),
		_make_cell(Vector2i(0, 1)),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.BACKGROUND, bg_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_int(result.background.size()).is_equal(3)
	assert_vector(result.background[0].position).is_equal(Vector2i(0, 0))
	assert_vector(result.background[1].position).is_equal(Vector2i(1, 0))


# --- Version ---

func test_build_sets_version_to_2() -> void:
	var data = _make_semantic_data()
	var result = RoomDataBuilder.new().build(data, Rect2i())
	assert_int(result.version).is_equal(2)


# --- Bounds ---

func test_build_copies_room_bounds() -> void:
	var data = _make_semantic_data()
	var room_bounds = Rect2i(1, 2, 3, 4)

	var result = RoomDataBuilder.new().build(data, room_bounds)

	assert_bool(result.room_bounds == Rect2i(1, 2, 3, 4)).is_true()


func test_build_computes_geometry_bounds() -> void:
	var data = _make_semantic_data()
	var platform_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO),
		_make_topology_cell(Vector2i(2, 1), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i(10, 10, 1, 1))

	# Geometry bounds: position (0,0), size (3,2) = from (0,0) to (2,1) inclusive.
	# It is derived from the cells and independent of the copied room_bounds.
	assert_int(result.geometry_bounds.position.x).is_equal(0)
	assert_int(result.geometry_bounds.position.y).is_equal(0)
	assert_int(result.geometry_bounds.size.x).is_equal(3)
	assert_int(result.geometry_bounds.size.y).is_equal(2)
	assert_bool(result.room_bounds == Rect2i(10, 10, 1, 1)).is_true()


func test_build_geometry_bounds_includes_walls() -> void:
	var data = _make_semantic_data()
	var platform_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(1, 1), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	var wall_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.WALL, wall_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	# Bounds should span from (0,0) to (1,1), so size is (2,2)
	assert_int(result.geometry_bounds.position.x).is_equal(0)
	assert_int(result.geometry_bounds.position.y).is_equal(0)
	assert_int(result.geometry_bounds.size.x).is_equal(2)
	assert_int(result.geometry_bounds.size.y).is_equal(2)


func test_build_empty_data_gives_zero_bounds() -> void:
	var data = _make_semantic_data()
	# No cells at all
	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i(5, 5, 2, 2))

	# Geometry bounds are derived from cells, so they are empty when no cells exist.
	assert_int(result.geometry_bounds.position.x).is_zero()
	assert_int(result.geometry_bounds.position.y).is_zero()
	assert_int(result.geometry_bounds.size.x).is_zero()
	assert_int(result.geometry_bounds.size.y).is_zero()
	# Room bounds are copied verbatim from the context, even when empty geometry.
	assert_bool(result.room_bounds == Rect2i(5, 5, 2, 2)).is_true()


# --- Markers ---

func test_build_copies_markers_sorted_by_type_then_position_then_ids() -> void:
	var data = _make_semantic_data()
	# Insert out of enum order to prove the builder re-sorts by type.
	var checkpoint = _make_marker(MarkerType.Value.CHECKPOINT, Vector2i(0, 0), &"cp", &"node_cp")
	var loot = _make_marker(MarkerType.Value.LOOT_SPAWN, Vector2i(0, 0), &"loot", &"chest")
	var enemy = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"enemy", &"goblin")
	data.markers.add_marker(MarkerType.Value.CHECKPOINT, checkpoint)
	data.markers.add_marker(MarkerType.Value.LOOT_SPAWN, loot)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, enemy)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	assert_int(result.markers.size()).is_equal(3)
	# Type order: ENEMY_SPAWN(0), LOOT_SPAWN(1), CHECKPOINT(2)
	assert_str(result.markers[0].marker_id).is_equal(&"enemy")
	assert_str(result.markers[1].marker_id).is_equal(&"loot")
	assert_str(result.markers[2].marker_id).is_equal(&"cp")


func test_build_sorts_markers_by_position_within_type() -> void:
	var data = _make_semantic_data()
	var at_one_zero = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(1, 0), &"a", &"c")
	var at_zero_one = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 1), &"b", &"c")
	var at_zero_zero = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"c", &"c")
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, at_one_zero)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, at_zero_one)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, at_zero_zero)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	# Position y first, then x: (0,0), (1,0), (0,1)
	assert_str(result.markers[0].marker_id).is_equal(&"c")
	assert_str(result.markers[1].marker_id).is_equal(&"a")
	assert_str(result.markers[2].marker_id).is_equal(&"b")


func test_build_sorts_markers_by_marker_id_then_content_id() -> void:
	var data = _make_semantic_data()
	var first = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"first", &"zzz")
	var second = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"second", &"aaa")
	# Same marker_id, differ only by content_id.
	var same_id_a = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"dup", &"beta")
	var same_id_b = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"dup", &"alpha")
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, first)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, second)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, same_id_a)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, same_id_b)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	# marker_id tiebreak, then content_id: dup/alpha, dup/beta, first, second
	assert_str(result.markers[0].marker_id).is_equal(&"dup")
	assert_str(result.markers[0].content_id).is_equal(&"alpha")
	assert_str(result.markers[1].marker_id).is_equal(&"dup")
	assert_str(result.markers[1].content_id).is_equal(&"beta")
	assert_str(result.markers[2].marker_id).is_equal(&"first")
	assert_str(result.markers[3].marker_id).is_equal(&"second")


func test_build_duplicates_marker_resources() -> void:
	var data = _make_semantic_data()
	var marker = _make_marker(MarkerType.Value.ENEMY_SPAWN, Vector2i(0, 0), &"enemy", &"goblin")
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, marker)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_int(result.markers.size()).is_equal(1)
	# The baked marker must not alias the intermediate semantic resource.
	assert_bool(result.markers[0] == marker).is_false()
	# But it must carry the same data.
	assert_str(result.markers[0].marker_id).is_equal(&"enemy")
	assert_vector(result.markers[0].position).is_equal(Vector2i(0, 0))
	assert_str(result.markers[0].content_id).is_equal(&"goblin")


func test_build_empty_markers_produces_empty_array() -> void:
	var data = _make_semantic_data()
	var result = RoomDataBuilder.new().build(data, Rect2i())
	assert_int(result.markers.size()).is_zero()


# --- Connections ---

func test_build_copies_connections_sorted_by_side_then_position() -> void:
	var data = _make_semantic_data()
	var top = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"top")
	var bottom = _make_connection(ConnectionSide.Value.BOTTOM, Vector2i(0, 0), &"bottom")
	var right = _make_connection(ConnectionSide.Value.RIGHT, Vector2i(0, 0), &"right")
	# Add out of side order to prove the builder re-sorts.
	data.connections.append(bottom)
	data.connections.append(right)
	data.connections.append(top)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	assert_int(result.connections.size()).is_equal(3)
	# Side order: TOP(0), BOTTOM(1), RIGHT(2)
	assert_str(result.connections[0].id).is_equal(&"top")
	assert_str(result.connections[1].id).is_equal(&"bottom")
	assert_str(result.connections[2].id).is_equal(&"right")


func test_build_sorts_connections_by_position_then_size_then_id() -> void:
	var data = _make_semantic_data()
	# Default size is 1x1. The later row proves position.y sorts before id.
	var later_row = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 1), &"aaa")
	# Sizes are deliberately paired with reversed ids so size must win over id.
	var wider = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"zzz", Vector2i(4, 1))
	var taller = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"aaa", Vector2i(4, 2))
	# Same side, position and size: id is the final tiebreaker.
	var first = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"first")
	var second = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"second")
	data.connections.append(later_row)
	data.connections.append(wider)
	data.connections.append(taller)
	data.connections.append(second)
	data.connections.append(first)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	# y=0 group: the 1x1 ties sort by id (first, second), then 4x1, then 4x2.
	assert_str(result.connections[0].id).is_equal(&"first")
	assert_str(result.connections[1].id).is_equal(&"second")
	assert_str(result.connections[2].id).is_equal(&"zzz")
	assert_str(result.connections[3].id).is_equal(&"aaa")
	# The later row sorts last even though its id sorts first alphabetically.
	assert_str(result.connections[4].id).is_equal(&"aaa")
	assert_vector(result.connections[4].position).is_equal(Vector2i(0, 1))


func test_build_sorts_connections_by_x_when_y_ties() -> void:
	var data = _make_semantic_data()
	var right = _make_connection(ConnectionSide.Value.TOP, Vector2i(2, 0), &"right")
	var left = _make_connection(ConnectionSide.Value.TOP, Vector2i(1, 0), &"left")
	# Same side and row, so only x can decide the order.
	data.connections.append(right)
	data.connections.append(left)

	var result = RoomDataBuilder.new().build(data, Rect2i())

	assert_str(result.connections[0].id).is_equal(&"left")
	assert_str(result.connections[1].id).is_equal(&"right")


func test_build_duplicates_connection_resources() -> void:
	var data = _make_semantic_data()
	var connection = _make_connection(ConnectionSide.Value.TOP, Vector2i(0, 0), &"main_exit", Vector2i(2, 1))
	data.connections.append(connection)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_int(result.connections.size()).is_equal(1)
	# The baked connection must not alias the intermediate semantic resource.
	assert_bool(result.connections[0] == connection).is_false()
	# But it must carry the same data.
	assert_str(result.connections[0].id).is_equal(&"main_exit")
	assert_int(result.connections[0].side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(result.connections[0].position).is_equal(Vector2i(0, 0))
	assert_vector(result.connections[0].size).is_equal(Vector2i(2, 1))


func test_build_empty_connections_produces_empty_array() -> void:
	var data = _make_semantic_data()
	var result = RoomDataBuilder.new().build(data, Rect2i())
	assert_int(result.connections.size()).is_zero()


# --- Version 1 compatibility ---

func test_version1_legacy_bounds_loads_as_geometry_bounds() -> void:
	# A version 1 resource serialized only a geometry-derived `bounds` property.
	# The load path must capture it through the compatibility setter and report
	# version 1, without populating the version 2 room_bounds.
	var room_data = RoomData.new()
	room_data.set(&"bounds", Rect2i(0, 0, 10, 10))

	assert_int(room_data.version).is_equal(1)
	assert_int(room_data.geometry_bounds.position.x).is_equal(0)
	assert_int(room_data.geometry_bounds.position.y).is_equal(0)
	assert_int(room_data.geometry_bounds.size.x).is_equal(10)
	assert_int(room_data.geometry_bounds.size.y).is_equal(10)
	assert_bool(room_data.room_bounds == Rect2i()).is_true()
	assert_int(room_data.markers.size()).is_zero()
	assert_int(room_data.connections.size()).is_zero()


func test_version1_legacy_bounds_not_overwritten_when_geometry_set() -> void:
	# If geometry_bounds already holds a value, the legacy bounds must not clobber it.
	var room_data = RoomData.new()
	room_data.geometry_bounds = Rect2i(0, 0, 5, 5)
	room_data.set(&"bounds", Rect2i(0, 0, 10, 10))

	assert_int(room_data.version).is_equal(1)
	assert_int(room_data.geometry_bounds.size.x).is_equal(5)
	assert_int(room_data.geometry_bounds.size.y).is_equal(5)


func test_unrelated_property_is_ignored_by_legacy_hook() -> void:
	# Only the legacy `bounds` property is captured; every other unknown
	# property must fall through without changing the resource.
	var room_data = RoomData.new()
	room_data.set(&"not_bounds", Rect2i(1, 1, 2, 2))

	assert_int(room_data.version).is_equal(2)
	assert_bool(room_data.geometry_bounds == Rect2i()).is_true()
	assert_bool(room_data.room_bounds == Rect2i()).is_true()


func test_new_baked_resource_defaults_to_version_2() -> void:
	var room_data = RoomData.new()
	assert_int(room_data.version).is_equal(2)
	assert_bool(room_data.room_bounds == Rect2i()).is_true()
	assert_bool(room_data.geometry_bounds == Rect2i()).is_true()
	assert_int(room_data.markers.size()).is_zero()
	assert_int(room_data.connections.size()).is_zero()


# --- Missing topology fallback ---

func test_build_fallback_shape_when_no_topology() -> void:
	var data = _make_semantic_data()
	# Cell without topology (plain SemanticSpatialCell, not TopologyCell)
	var cells: Array[SemanticSpatialCell] = [
		_make_cell(Vector2i(0, 0)),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_int(result.platforms.size()).is_equal(1)
	# Falls back to SINGLE
	assert_int(result.platforms[0].shape).is_equal(CellShape.Value.SINGLE)
	assert_int(result.platforms[0].corners).is_equal(CellCorner.Value.NO)


# --- RoomData is a Resource ---

func test_build_returns_room_data_resource() -> void:
	var data = _make_semantic_data()
	var builder = RoomDataBuilder.new()
	var result = builder.build(data, Rect2i())

	assert_bool(result is RoomData).is_true()
