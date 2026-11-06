## PostBakeTopologyProcessor unit tests.
## Covers: isolated cell, full cell, line cells, corner detection, empty input, single neighbour.
extends GdUnitTestSuite


func _make_topology_cell(position: Vector2i) -> SemanticSpatialTopologyCell:
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = position
	# topology starts null; the processor assigns it
	return cell


# --- Empty input ---

func test_empty_input_returns_empty() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var cells: Array[SemanticSpatialCell] = []
	var result = processor.execute(cells)
	assert_int(result.size()).is_zero()


# --- Isolated cell: no neighbours -> SINGLE + ALL ---

func test_isolated_cell_gets_single_and_all() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var cell = _make_topology_cell(Vector2i(5, 5))
	var cells: Array[SemanticSpatialCell] = [cell]
	var result = processor.execute(cells)

	assert_int(result.size()).is_equal(1)
	var output = result[0] as SemanticSpatialTopologyCell
	assert_object(output).is_not_null()
	assert_object(output.topology).is_not_null()
	assert_int(output.topology.shape).is_equal(CellShape.Value.SINGLE)
	assert_int(output.topology.corner).is_equal(CellCorner.Value.ALL)


# --- Horizontal line: 3 cells in a row, all have no top/bottom neighbours ---

func test_horizontal_line_cells_get_single() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(0, 0)),
		_make_topology_cell(Vector2i(1, 0)),
		_make_topology_cell(Vector2i(2, 0)),
	]
	var result = processor.execute(cells)

	# Leftmost cell: has right neighbour, no top/bottom/left -> SINGLE, RIGHT corner
	assert_int(result[0].topology.shape).is_equal(CellShape.Value.SINGLE)
	# Middle cell: has left + right, no top/bottom -> SINGLE, NO corner (straight line)
	assert_int(result[1].topology.shape).is_equal(CellShape.Value.SINGLE)
	# Rightmost cell: has left neighbour, no top/bottom/right -> SINGLE, LEFT corner
	assert_int(result[2].topology.shape).is_equal(CellShape.Value.SINGLE)


# --- Full cell: all 4 neighbours present -> FULL + NO ---

func test_full_cell_gets_full_and_no() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var center = Vector2i(1, 1)
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(center),
		_make_topology_cell(center + Vector2i.UP),
		_make_topology_cell(center + Vector2i.DOWN),
		_make_topology_cell(center + Vector2i.LEFT),
		_make_topology_cell(center + Vector2i.RIGHT),
	]
	var result = processor.execute(cells)

	# Find the center cell in results
	var center_result: SemanticSpatialTopologyCell = null
	for cell in result:
		var tc = cell as SemanticSpatialTopologyCell
		if tc.cell == center:
			center_result = tc
			break

	assert_object(center_result).is_not_null()
	assert_int(center_result.topology.shape).is_equal(CellShape.Value.FULL)
	assert_int(center_result.topology.corner).is_equal(CellCorner.Value.NO)


# --- L-shape corner: TOP + LEFT neighbours present, BOTTOM + RIGHT missing ---

func test_l_shape_cell_gets_bottom_right_corner() -> void:
	var processor = PostBakeTopologyProcessor.new()
	# Corner at (1,1) with neighbours at top (1,0) and left (0,1)
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(Vector2i(1, 1)),  # the corner cell
		_make_topology_cell(Vector2i(1, 0)),  # top
		_make_topology_cell(Vector2i(0, 1)),  # left
	]
	var result = processor.execute(cells)

	var corner_result: SemanticSpatialTopologyCell = null
	for cell in result:
		var tc = cell as SemanticSpatialTopologyCell
		if tc.cell == Vector2i(1, 1):
			corner_result = tc
			break

	assert_object(corner_result).is_not_null()
	# Has top and left, missing bottom and right -> shape = BOTTOM
	assert_int(corner_result.topology.shape).is_equal(CellShape.Value.BOTTOM)
	# Corner: bottom_right
	assert_int(corner_result.topology.corner).is_equal(CellCorner.Value.BOTTOM_RIGHT)


# --- Edge cell: missing TOP only -> TOP shape ---

func test_missing_top_neighbour_gives_top_shape() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var center = Vector2i(1, 1)
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(center),
		_make_topology_cell(center + Vector2i.DOWN),
		_make_topology_cell(center + Vector2i.LEFT),
		_make_topology_cell(center + Vector2i.RIGHT),
	]
	# No top neighbour
	var result = processor.execute(cells)

	var center_result: SemanticSpatialTopologyCell = null
	for cell in result:
		var tc = cell as SemanticSpatialTopologyCell
		if tc.cell == center:
			center_result = tc
			break

	assert_object(center_result).is_not_null()
	assert_int(center_result.topology.shape).is_equal(CellShape.Value.TOP)


# --- BOTTOM_RIGHT corner: missing bottom and right ---

func test_missing_bottom_right_gives_bottom_right_corner() -> void:
	var processor = PostBakeTopologyProcessor.new()
	var center = Vector2i(1, 1)
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(center),
		_make_topology_cell(center + Vector2i.UP),
		_make_topology_cell(center + Vector2i.LEFT),
	]
	# Missing bottom and right
	var result = processor.execute(cells)

	var center_result: SemanticSpatialTopologyCell = null
	for cell in result:
		var tc = cell as SemanticSpatialTopologyCell
		if tc.cell == center:
			center_result = tc
			break

	assert_object(center_result).is_not_null()
	# Has top and left, missing bottom and right
	assert_int(center_result.topology.shape).is_equal(CellShape.Value.BOTTOM)
	assert_int(center_result.topology.corner).is_equal(CellCorner.Value.BOTTOM_RIGHT)
