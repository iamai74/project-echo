## Test suite for BackgroundBakeProcessor.
## Covers: empty brushes, background cell creation, multi-cell brushes,
## and layer isolation.
extends GdUnitTestSuite


func test_empty_brush_array_adds_no_cells() -> void:
	var processor = BackgroundBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brushes: Array[SemanticBrush] = []

	processor.execute(brushes, room_data)

	assert_array(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)).has_size(0)


func test_background_cells_are_created() -> void:
	var processor = BackgroundBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(BackgroundBrush.new())
	brush.position = Vector2(32, 32)
	brush.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	assert_int(cells.size()).is_equal(1)
	assert_object(cells[0]).is_class(&"SemanticSpatialCell")


func test_multi_cell_brush_creates_full_rectangle() -> void:
	var processor = BackgroundBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(BackgroundBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(2, 3)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	assert_int(cells.size()).is_equal(6)


func test_platform_and_wall_layers_unchanged() -> void:
	var processor = BackgroundBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(BackgroundBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	assert_int(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_zero()
	assert_int(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL).size()).is_zero()
