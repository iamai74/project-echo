class_name RoomDataBuilder
extends RefCounted


func build(semantic_data: SemanticRoomData) -> RoomData:
	var room_data = RoomData.new()

	room_data.platforms = _to_semantic_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.FLOOR)
	)
	room_data.walls = _to_semantic_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)
	)
	room_data.background = _to_background_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	)
	room_data.bounds = _compute_bounds(semantic_data.spatial_layers)

	return room_data


func _to_semantic_cells(source: Array[SemanticSpatialCell]) -> Array[SemanticCell]:
	var result: Array[SemanticCell] = []
	for cell in source:
		var sc = SemanticCell.new()
		sc.position = cell.cell
		sc.shape = _read_shape(cell)
		sc.corners = _read_corner(cell)
		result.append(sc)
	return result


func _to_background_cells(source: Array[SemanticSpatialCell]) -> Array[BackgroundCell]:
	var result: Array[BackgroundCell] = []
	for cell in source:
		var bc = BackgroundCell.new()
		bc.position = cell.cell
		result.append(bc)
	return result


func _read_shape(cell: SemanticSpatialCell) -> CellShape.Value:
	var topo = cell as SemanticSpatialTopologyCell
	if topo != null and topo.topology != null:
		return topo.topology.shape
	return CellShape.Value.SINGLE


func _read_corner(cell: SemanticSpatialCell) -> CellCorner.Value:
	var topo = cell as SemanticSpatialTopologyCell
	if topo != null and topo.topology != null:
		return topo.topology.corner
	return CellCorner.Value.NO


func _compute_bounds(spatial_layers: SpatialLayer) -> Rect2i:
	var all_cells: Array[SemanticSpatialCell] = []
	all_cells.append_array(spatial_layers.get_cells(SpatialLayer.SpatialType.FLOOR))
	all_cells.append_array(spatial_layers.get_cells(SpatialLayer.SpatialType.WALL))

	if all_cells.is_empty():
		return Rect2i()

	var min_pos = all_cells[0].cell
	var max_pos = all_cells[0].cell
	for cell in all_cells:
		min_pos.x = min(min_pos.x, cell.cell.x)
		min_pos.y = min(min_pos.y, cell.cell.y)
		max_pos.x = max(max_pos.x, cell.cell.x)
		max_pos.y = max(max_pos.y, cell.cell.y)

	var size = (max_pos - min_pos) + Vector2i.ONE
	return Rect2i(min_pos, size)
