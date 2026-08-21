class_name WallBakeProcessor
extends BakeProcessor


func execute(brushes: Array[SemanticBrush], semantic_room: SemanticRoomData) -> void:
	for brush in brushes:
		_bake_platform(brush as WallBrush, semantic_room)


func _bake_platform(brush: WallBrush, semantic_room: SemanticRoomData) -> void:
	var rect := brush.get_grid_rect()
	var empty_cells: Array[SemanticSpatialTopologyCell] = []
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			empty_cells.append(_create_cell(cell))
	var result_cells: Array[SemanticSpatialCell] = []
	result_cells.assign(empty_cells)
	semantic_room.spatial_layers.add_cells(SpatialLayer.SpatialType.WALL, result_cells)


func _create_cell(cell: Vector2i) -> SemanticSpatialTopologyCell:
	var tile := SemanticSpatialTopologyCell.new()
	tile.cell = cell
	return tile
