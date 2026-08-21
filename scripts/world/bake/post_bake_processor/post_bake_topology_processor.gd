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
		topology.corner = SpatialTopology.Corner.NO
		if topology.shape == SpatialTopology.Shape.SINGLE:
			topology.corner = check_corners_for_single(neighbors)
		elif topology.shape != SpatialTopology.Shape.FULL:
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


func _check_shape(neighbors: Dictionary[NeighborType, bool]) -> SpatialTopology.Shape:
	var horizontal = !neighbors[NeighborType.TOP] && !neighbors[NeighborType.BOTTOM]
	var vertical = !neighbors[NeighborType.LEFT] && !neighbors[NeighborType.LEFT]
	if horizontal || vertical:
		return SpatialTopology.Shape.SINGLE
	if !neighbors[NeighborType.TOP]:
		return SpatialTopology.Shape.BOTTOM
	if !neighbors[NeighborType.BOTTOM]:
		return SpatialTopology.Shape.TOP
	if !neighbors[NeighborType.RIGHT]:
		return SpatialTopology.Shape.LEFT
	if !neighbors[NeighborType.LEFT]:
		return SpatialTopology.Shape.RIGHT
	return SpatialTopology.Shape.FULL


func check_basic_corners(neighbors: Dictionary[NeighborType, bool]) -> SpatialTopology.Corner:
	if !neighbors[NeighborType.TOP]:
		if !neighbors[NeighborType.LEFT]:
			return SpatialTopology.Corner.TOP_LEFT
		if !neighbors[NeighborType.RIGHT]:
			return SpatialTopology.Corner.TOP_RIGHT
	if !neighbors[NeighborType.BOTTOM]:
		if !neighbors[NeighborType.LEFT]:
			return SpatialTopology.Corner.BOTTOM_LEFT
		if !neighbors[NeighborType.RIGHT]:
			return SpatialTopology.Corner.BOTTOM_RIGHT
	return SpatialTopology.Corner.NO


func check_corners_for_single(neighbors: Dictionary[NeighborType, bool]) -> SpatialTopology.Corner:
	var full_single = true
	for key in NeighborType.keys():
		if neighbors[NeighborType.get(key)]:
			full_single = false
			break
	if full_single:
		return SpatialTopology.Corner.ALL

	if !neighbors[NeighborType.TOP]:
		if !neighbors[NeighborType.LEFT]:
			if !neighbors[NeighborType.BOTTOM]:
				return SpatialTopology.Corner.LEFT
			if !neighbors[NeighborType.RIGHT]:
				return SpatialTopology.Corner.TOP
		if !neighbors[NeighborType.RIGHT] && !neighbors[NeighborType.BOTTOM]:
			return SpatialTopology.Corner.RIGHT
	if !neighbors[NeighborType.BOTTOM]:
		if !neighbors[NeighborType.LEFT] && !neighbors[NeighborType.RIGHT]:
			return SpatialTopology.Corner.BOTTOM
	return SpatialTopology.Corner.NO


func _empty_neigbors_dict() -> Dictionary[NeighborType, bool]:
	var dict: Dictionary[NeighborType, bool] = {}
	for type in NeighborType.keys():
		dict[NeighborType.get(type)] = true
	return dict
