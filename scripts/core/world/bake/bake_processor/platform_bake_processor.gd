class_name PlatformBakeProcessor
extends BakeProcessor


func execute(brushes: Array[SemanticBrush], semantic_room: SemanticRoomData) -> void:
	for brush in brushes:
		_bake_platform(brush as PlatformBrush, semantic_room)


func _bake_platform(brush: PlatformBrush, semantic_room: SemanticRoomData) -> void:
	var rect := brush.get_grid_rect()
	var platform_cells: Array[SemanticSpatialCell] = []
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			platform_cells.append(_create_cell(brush, cell))
	semantic_room.spatial_layers.add_cells(SpatialLayer.SpatialType.FLOOR, platform_cells)


func _create_cell(brush: PlatformBrush, cell: Vector2i) -> SemanticSpatialFloorCell:
	var tile := SemanticSpatialFloorCell.new()
	if brush.has_trait(PlatformBrush.Trait.ONE_WAY):
		tile.traits.append(SemanticSpatialFloorCell.Trait.ONE_WAY)
	if brush.has_trait(PlatformBrush.Trait.BREAKABLE):
		tile.traits.append(SemanticSpatialFloorCell.Trait.BREAKABLE)
	tile.cell = cell
	return tile
