class_name BackgroundBakeProcessor
extends BakeProcessor


func execute(brushes: Array[SemanticBrush], semantic_room: SemanticRoomData) -> void:
	for brush in brushes:
		_bake_platform(brush as BackgroundBrush, semantic_room)


func _bake_platform(brush: BackgroundBrush, semantic_room: SemanticRoomData) -> void:
	var rect := brush.get_grid_rect()
	var platform_cells: Array[SemanticSpatialCell] = []
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			platform_cells.append(_create_cell(cell))
	semantic_room.spatial_layers.add_cells(SpatialLayer.SpatialType.BACKGROUND, platform_cells)


func _create_cell(cell: Vector2i) -> SemanticSpatialCell:
	var tile := SemanticSpatialCell.new()
	tile.cell = cell
	return tile
