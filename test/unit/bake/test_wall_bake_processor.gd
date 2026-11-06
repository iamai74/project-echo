## Test suite for WallBakeProcessor.
## Covers: empty brushes, wall cell creation, multi-cell brushes,
## and layer isolation.
extends GdUnitTestSuite


func test_empty_brush_array_adds_no_cells() -> void:
	var processor = WallBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brushes: Array[SemanticBrush] = []

	processor.execute(brushes, room_data)

	assert_array(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)).has_size(0)


func test_wall_cells_are_topology_cells() -> void:
	var processor = WallBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(WallBrush.new())
	brush.position = Vector2(32, 32)
	brush.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)
	assert_int(cells.size()).is_equal(1)
	assert_object(cells[0]).is_class(&"SemanticSpatialTopologyCell")


func test_multi_cell_brush_creates_full_rectangle() -> void:
	var processor = WallBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(WallBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(3, 2)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)
	assert_int(cells.size()).is_equal(6)


func test_cells_added_to_wall_layer_only() -> void:
	var processor = WallBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(WallBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	assert_int(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL).size()).is_equal(1)
	assert_int(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_zero()
	assert_int(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND).size()).is_zero()
