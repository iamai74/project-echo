class_name PostBakeTopologyProcessor
extends PostBakeProcessor

enum NeighborType { TOP, BOTTOM, LEFT, RIGHT }

var _cells: Array[SemanticSpatialTopologyCell]
var _cells_dict: Dictionary[Vector2i, SemanticSpatialTopologyCell]


func execute(cells: Array[SemanticSpatialCell]) -> Array[SemanticSpatialCell]:
	var empty_arr: Array[SemanticSpatialTopologyCell] = []
	empty_arr.assign(cells)
	_cells = empty_arr
	for cell in _cells:
		_cells_dict[cell.cell] = cell

	for cell in _cells:
		var topology = SpatialTopology.new()
		var neighbors = _check_neigbhors(cell.cell)
		topology.shape = _check_shape(neighbors)
		topology.corner = CellCorner.Value.NO
		if topology.shape == CellShape.Value.SINGLE:
			topology.corner = check_corners_for_single(neighbors)
		elif topology.shape != CellShape.Value.FULL:
			topology.corner = check_basic_corners(neighbors)
		cell.topology = topology

	var result_array: Array[SemanticSpatialCell]
	result_array.assign(_cells)
	return result_array


func _check_neigbhors(cell: Vector2i) -> Dictionary[NeighborType, bool]:
	var neighbors = _empty_neigbors_dict()
	var top = Vector2i(cell.x, cell.y - 1)
	if !_cells_dict.has(top):
		neighbors[NeighborType.TOP] = false
	var bottom = Vector2i(cell.x, cell.y + 1)
	if !_cells_dict.has(bottom):
		neighbors[NeighborType.BOTTOM] = false
	var left = Vector2i(cell.x - 1, cell.y)
	if !_cells_dict.has(left):
		neighbors[NeighborType.LEFT] = false
	var right = Vector2i(cell.x + 1, cell.y)
	if !_cells_dict.has(right):
		neighbors[NeighborType.RIGHT] = false
	return neighbors


func _check_shape(neighbors: Dictionary[NeighborType, bool]) -> CellShape.Value:
	var horizontal = !neighbors[NeighborType.TOP] && !neighbors[NeighborType.BOTTOM]
	var vertical = !neighbors[NeighborType.LEFT] && !neighbors[NeighborType.RIGHT]
	if horizontal || vertical:
		return CellShape.Value.SINGLE
	if !neighbors[NeighborType.TOP]:
		return CellShape.Value.TOP
	if !neighbors[NeighborType.BOTTOM]:
		return CellShape.Value.BOTTOM
	if !neighbors[NeighborType.LEFT]:
		return CellShape.Value.LEFT
	if !neighbors[NeighborType.RIGHT]:
		return CellShape.Value.RIGHT
	return CellShape.Value.FULL


func check_basic_corners(neighbors: Dictionary[NeighborType, bool]) -> CellCorner.Value:
	if !neighbors[NeighborType.TOP]:
		if !neighbors[NeighborType.LEFT]:
			return CellCorner.Value.TOP_LEFT
		if !neighbors[NeighborType.RIGHT]:
			return CellCorner.Value.TOP_RIGHT
	if !neighbors[NeighborType.BOTTOM]:
		if !neighbors[NeighborType.LEFT]:
			return CellCorner.Value.BOTTOM_LEFT
		if !neighbors[NeighborType.RIGHT]:
			return CellCorner.Value.BOTTOM_RIGHT
	return CellCorner.Value.NO


func check_corners_for_single(neighbors: Dictionary[NeighborType, bool]) -> CellCorner.Value:
	var full_single = true
	for key in NeighborType.keys():
		if neighbors[NeighborType.get(key)]:
			full_single = false
			break
	if full_single:
		return CellCorner.Value.ALL
	
	if !neighbors[NeighborType.TOP]:
		if !neighbors[NeighborType.LEFT]:
			if !neighbors[NeighborType.BOTTOM]:
				return CellCorner.Value.LEFT
			if !neighbors[NeighborType.RIGHT]:
				return CellCorner.Value.TOP
		if !neighbors[NeighborType.RIGHT] && !neighbors[NeighborType.BOTTOM]:
			return CellCorner.Value.RIGHT
	if !neighbors[NeighborType.BOTTOM]:
		if !neighbors[NeighborType.LEFT] && !neighbors[NeighborType.RIGHT]:
			return CellCorner.Value.BOTTOM
	return CellCorner.Value.NO


func _empty_neigbors_dict() -> Dictionary[NeighborType, bool]:
	var dict: Dictionary[NeighborType, bool] = {}
	for type in NeighborType.keys():
		dict[NeighborType.get(type)] = true
	return dict
