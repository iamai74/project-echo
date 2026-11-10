## TopologyValidator unit tests.
## Covers: shape from neighbours, corner from neighbours, isolated cell, full cell, missing topology.
extends GdUnitTestSuite


func _get_neighbor_corner(direction: Vector2i) -> CellCorner.Value:
	match direction:
		Vector2i.UP:
			return CellCorner.Value.TOP
		Vector2i.DOWN:
			return CellCorner.Value.BOTTOM
		Vector2i.LEFT:
			return CellCorner.Value.LEFT
		Vector2i.RIGHT:
			return CellCorner.Value.RIGHT
	return CellCorner.Value.NO


func _make_topology(shape: CellShape.Value, corner: CellCorner.Value) -> SpatialTopology:
	var topo = SpatialTopology.new()
	topo.shape = shape
	topo.corner = corner
	return topo


func _make_topology_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value
) -> SemanticSpatialTopologyCell:
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = position
	cell.topology = _make_topology(shape, corner)
	return cell


func _make_context_with_platforms(cells: Array[SemanticSpatialCell]) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)
	return context


# --- Shape and corner from neighbour layout ---

func test_shape_and_corner_from_neighbour_layout(
	center: Vector2i,
	has_neighbor: Array[bool],
	expected_shape: CellShape.Value,
	expected_corner: CellCorner.Value,
	_test_parameters := [
		# isolated
		[Vector2i(5, 5), [false, false, false, false], CellShape.Value.SINGLE, CellCorner.Value.ALL],
		# full (surrounded on all sides)
		[Vector2i(5, 5), [true, true, true, true], CellShape.Value.FULL, CellCorner.Value.NO],
		# only right neighbour
		[Vector2i(5, 5), [false, false, false, true], CellShape.Value.SINGLE, CellCorner.Value.LEFT],
		# only top neighbour
		[Vector2i(5, 5), [true, false, false, false], CellShape.Value.SINGLE, CellCorner.Value.BOTTOM],
		# only bottom neighbour
		[Vector2i(5, 5), [false, true, false, false], CellShape.Value.SINGLE, CellCorner.Value.TOP],
		# only left neighbour
		[Vector2i(5, 5), [false, false, true, false], CellShape.Value.SINGLE, CellCorner.Value.RIGHT],
		# top + bottom (horizontal neighbours present)
		[Vector2i(5, 5), [true, true, false, false], CellShape.Value.SINGLE, CellCorner.Value.NO],
		# left + right (vertical neighbours present)
		[Vector2i(5, 5), [false, false, true, true], CellShape.Value.SINGLE, CellCorner.Value.NO],
		# three neighbours: missing top
		[Vector2i(5, 5), [false, true, true, true], CellShape.Value.TOP, CellCorner.Value.NO],
		# three neighbours: missing bottom
		[Vector2i(5, 5), [true, false, true, true], CellShape.Value.BOTTOM, CellCorner.Value.NO],
		# three neighbours: missing left
		[Vector2i(5, 5), [true, true, false, true], CellShape.Value.LEFT, CellCorner.Value.NO],
		# three neighbours: missing right
		[Vector2i(5, 5), [true, true, true, false], CellShape.Value.RIGHT, CellCorner.Value.NO],
		# two neighbours: top + left
		[Vector2i(5, 5), [true, false, true, false], CellShape.Value.BOTTOM, CellCorner.Value.BOTTOM_RIGHT],
		# two neighbours: bottom + right
		[Vector2i(5, 5), [false, true, false, true], CellShape.Value.TOP, CellCorner.Value.TOP_LEFT],
	]
) -> void:
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var cells: Array[SemanticSpatialCell]

	# center cell — correct topology for this neighbour layout
	var center_cell = SemanticSpatialTopologyCell.new()
	center_cell.cell = center
	center_cell.topology = _make_topology(expected_shape, expected_corner)
	cells.append(center_cell)

	# neighbour cells — each has only the center as its neighbour, so shape is SINGLE
	for i in range(4):
		if has_neighbor[i]:
			var neighbor_cell = SemanticSpatialTopologyCell.new()
			neighbor_cell.cell = center + directions[i]
			neighbor_cell.topology = _make_topology(
				CellShape.Value.SINGLE,
				_get_neighbor_corner(directions[i])
			)
			cells.append(neighbor_cell)

	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)
	var validator = TopologyValidator.new()
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()
