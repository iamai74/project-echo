## SpatialLayer unit tests.
## Covers: add/set/get, duplicate cell rejection, unknown type returns empty, array isolation.
extends GdUnitTestSuite


var layer: SpatialLayer


func before_test() -> void:
	layer = SpatialLayer.new()


func test_get_cells_returns_empty_for_unknown_type() -> void:
	var cells = layer.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_bool(cells is Array).is_true()
	assert_int(cells.size()).is_zero()


func test_add_cell_returns_true_on_success() -> void:
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(0, 0)
	var result = layer.add_cell(SpatialLayer.SpatialType.PLATFORM, cell)
	assert_bool(result).is_true()


func test_add_cell_rejects_duplicate() -> void:
	var cell1 = SemanticSpatialCell.new()
	cell1.cell = Vector2i(0, 0)
	var cell2 = SemanticSpatialCell.new()
	cell2.cell = Vector2i(0, 0)
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.PLATFORM, cell1)).is_true()
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.PLATFORM, cell2)).is_false()


func test_add_cell_allows_different_positions() -> void:
	var cell1 = SemanticSpatialCell.new()
	cell1.cell = Vector2i(0, 0)
	var cell2 = SemanticSpatialCell.new()
	cell2.cell = Vector2i(1, 0)
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.PLATFORM, cell1)).is_true()
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.PLATFORM, cell2)).is_true()
	assert_int(layer.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_equal(2)


func test_add_cells_appends_array() -> void:
	var cells: Array[SemanticSpatialCell] = []
	var c1 = SemanticSpatialCell.new()
	c1.cell = Vector2i(0, 0)
	var c2 = SemanticSpatialCell.new()
	c2.cell = Vector2i(1, 0)
	cells.append(c1)
	cells.append(c2)
	layer.add_cells(SpatialLayer.SpatialType.PLATFORM, cells)
	assert_int(layer.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_equal(2)


func test_set_cells_replaces_all() -> void:
	var cell1 = SemanticSpatialCell.new()
	cell1.cell = Vector2i(0, 0)
	layer.add_cell(SpatialLayer.SpatialType.WALL, cell1)
	assert_int(layer.get_cells(SpatialLayer.SpatialType.WALL).size()).is_equal(1)

	var new_cells: Array[SemanticSpatialCell] = []
	var nc = SemanticSpatialCell.new()
	nc.cell = Vector2i(5, 5)
	new_cells.append(nc)
	layer.set_cells(SpatialLayer.SpatialType.WALL, new_cells)
	assert_int(layer.get_cells(SpatialLayer.SpatialType.WALL).size()).is_equal(1)
	assert_vector(layer.get_cells(SpatialLayer.SpatialType.WALL)[0].cell).is_equal(Vector2i(5, 5))


func test_layer_isolation_between_types() -> void:
	var platform_cell = SemanticSpatialCell.new()
	platform_cell.cell = Vector2i(0, 0)
	var wall_cell = SemanticSpatialCell.new()
	wall_cell.cell = Vector2i(0, 0)
	layer.add_cell(SpatialLayer.SpatialType.PLATFORM, platform_cell)
	layer.add_cell(SpatialLayer.SpatialType.WALL, wall_cell)
	assert_int(layer.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_equal(1)
	assert_int(layer.get_cells(SpatialLayer.SpatialType.WALL).size()).is_equal(1)


func test_duplicate_across_types_allowed() -> void:
	var c1 = SemanticSpatialCell.new()
	c1.cell = Vector2i(2, 2)
	var c2 = SemanticSpatialCell.new()
	c2.cell = Vector2i(2, 2)
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.PLATFORM, c1)).is_true()
	assert_bool(layer.add_cell(SpatialLayer.SpatialType.BACKGROUND, c2)).is_true()
