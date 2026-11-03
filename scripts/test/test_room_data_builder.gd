## RoomDataBuilder unit tests.
## Covers: platform/wall/background cell conversion, bounds computation, empty data, 
## topology cell data extraction, missing topology fallback.
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


# --- Basic conversion ---

func test_build_converts_platform_cells() -> void:
	var data = _make_semantic_data()
	var platform_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.ALL),
		_make_topology_cell(Vector2i(1, 0), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data)

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
	var result = builder.build(data)

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
	var result = builder.build(data)

	assert_int(result.background.size()).is_equal(3)
	assert_vector(result.background[0].position).is_equal(Vector2i(0, 0))
	assert_vector(result.background[1].position).is_equal(Vector2i(1, 0))


# --- Bounds computation ---

func test_build_computes_bounds() -> void:
	var data = _make_semantic_data()
	var platform_cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO),
		_make_topology_cell(Vector2i(2, 1), CellShape.Value.SINGLE, CellCorner.Value.NO),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data)

	# Bounds: position (0,0), size (3,2) = from (0,0) to (2,1) inclusive
	assert_int(result.bounds.position.x).is_equal(0)
	assert_int(result.bounds.position.y).is_equal(0)
	assert_int(result.bounds.size.x).is_equal(3)
	assert_int(result.bounds.size.y).is_equal(2)


func test_build_bounds_includes_walls() -> void:
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
	var result = builder.build(data)

	# Bounds should span from (0,0) to (1,1), so size is (2,2)
	assert_int(result.bounds.position.x).is_equal(0)
	assert_int(result.bounds.position.y).is_equal(0)
	assert_int(result.bounds.size.x).is_equal(2)
	assert_int(result.bounds.size.y).is_equal(2)


func test_build_empty_data_gives_zero_bounds() -> void:
	var data = _make_semantic_data()
	# No cells at all
	var builder = RoomDataBuilder.new()
	var result = builder.build(data)

	assert_int(result.bounds.position.x).is_zero()
	assert_int(result.bounds.position.y).is_zero()
	assert_int(result.bounds.size.x).is_zero()
	assert_int(result.bounds.size.y).is_zero()


# --- Missing topology fallback ---

func test_build_fallback_shape_when_no_topology() -> void:
	var data = _make_semantic_data()
	# Cell without topology (plain SemanticSpatialCell, not TopologyCell)
	var cells: Array[SemanticSpatialCell] = [
		_make_cell(Vector2i(0, 0)),
	]
	data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)

	var builder = RoomDataBuilder.new()
	var result = builder.build(data)

	assert_int(result.platforms.size()).is_equal(1)
	# Falls back to SINGLE
	assert_int(result.platforms[0].shape).is_equal(CellShape.Value.SINGLE)
	assert_int(result.platforms[0].corners).is_equal(CellCorner.Value.NO)


# --- RoomData is a Resource ---

func test_build_returns_room_data_resource() -> void:
	var data = _make_semantic_data()
	var builder = RoomDataBuilder.new()
	var result = builder.build(data)

	assert_bool(result is RoomData).is_true()
