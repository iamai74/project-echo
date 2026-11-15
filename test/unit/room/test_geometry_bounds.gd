## GeometryBounds unit tests.
## Covers: empty layers, single and mixed platform/wall cells, background
## exclusion, negative coordinates, has_area and marker/connection independence.
extends GdUnitTestSuite


func _cell(x: int, y: int) -> SemanticSpatialCell:
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(x, y)
	return cell


# --- Empty geometry ---

func test_compute_empty_layers_returns_empty() -> void:
	var layers = SpatialLayer.new()
	var result = GeometryBounds.compute(layers)
	assert_bool(result == Rect2i()).is_true()
	assert_int(result.size.x).is_zero()
	assert_int(result.size.y).is_zero()


func test_from_cells_empty_returns_empty() -> void:
	var cells: Array[SemanticSpatialCell] = []
	var result = GeometryBounds.from_cells(cells)
	assert_bool(result == Rect2i()).is_true()


# --- Single cells ---

func test_compute_single_platform_cell() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [ _cell(4, 5) ])
	var result = GeometryBounds.compute(layers)
	assert_int(result.position.x).is_equal(4)
	assert_int(result.position.y).is_equal(5)
	assert_int(result.size.x).is_equal(1)
	assert_int(result.size.y).is_equal(1)


func test_compute_single_wall_cell() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.WALL, [ _cell(7, 2) ])
	var result = GeometryBounds.compute(layers)
	assert_int(result.position.x).is_equal(7)
	assert_int(result.position.y).is_equal(2)
	assert_int(result.size.x).is_equal(1)
	assert_int(result.size.y).is_equal(1)


# --- Mixed cells ---

func test_compute_mixed_platform_and_wall_union() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [ _cell(1, 1), _cell(3, 4) ])
	layers.add_cells(SpatialLayer.SpatialType.WALL, [ _cell(0, 0), _cell(2, 6) ])
	var result = GeometryBounds.compute(layers)
	# Min corner (0,0), max corner (3,6) -> size (4,7).
	assert_int(result.position.x).is_equal(0)
	assert_int(result.position.y).is_equal(0)
	assert_int(result.size.x).is_equal(4)
	assert_int(result.size.y).is_equal(7)


# --- Background exclusion ---

func test_background_cells_do_not_contribute() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.BACKGROUND, [ _cell(0, 0), _cell(9, 9) ])
	var result = GeometryBounds.compute(layers)
	assert_bool(result == Rect2i()).is_true()


func test_platform_ignores_background() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.BACKGROUND, [ _cell(-3, -3), _cell(10, 10) ])
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [ _cell(2, 2) ])
	var result = GeometryBounds.compute(layers)
	# Only the platform cell bounds the extent.
	assert_int(result.position.x).is_equal(2)
	assert_int(result.position.y).is_equal(2)
	assert_int(result.size.x).is_equal(1)
	assert_int(result.size.y).is_equal(1)


# --- Negative coordinates ---

func test_compute_negative_coordinates() -> void:
	var layers = SpatialLayer.new()
	layers.add_cells(SpatialLayer.SpatialType.PLATFORM, [ _cell(-3, -2), _cell(1, 2) ])
	var result = GeometryBounds.compute(layers)
	# Min (-3,-2), max (1,2) -> size (5,5).
	assert_int(result.position.x).is_equal(-3)
	assert_int(result.position.y).is_equal(-2)
	assert_int(result.size.x).is_equal(5)
	assert_int(result.size.y).is_equal(5)


# --- has_area ---

func test_has_area_empty_and_populated() -> void:
	assert_bool(GeometryBounds.has_area(Rect2i())).is_false()
	assert_bool(GeometryBounds.has_area(Rect2i(0, 0, 4, 4))).is_true()


# --- Marker and connection independence ---

func test_independent_of_markers_and_connections() -> void:
	var data = SemanticRoomData.new()
	var platform_cells: Array[SemanticSpatialCell] = [ _cell(1, 1), _cell(4, 4) ]
	data.spatial_layers.add_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)
	var before = GeometryBounds.compute(data.spatial_layers)

	# Adding markers and connections must not change the geometry extent.
	var marker = MarkerData.new()
	marker.position = Vector2i(10, 10)
	data.markers.add_marker(MarkerType.Value.ENEMY_SPAWN, marker)

	var connection = ConnectionData.new()
	connection.position = Vector2i(20, 20)
	connection.size = Vector2i(3, 1)
	data.connections.append(connection)

	var after = GeometryBounds.compute(data.spatial_layers)
	assert_bool(before == after).is_true()
	assert_int(after.position.x).is_equal(1)
	assert_int(after.size.x).is_equal(4)
