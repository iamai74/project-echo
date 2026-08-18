class_name PlatformBakeProcessor
extends BakeProcessor


func execute(brushes: Array[SemanticBrush], semantic_room: SemanticRoomData) -> void:
	for brush in brushes:
		_bake_platform(brush as PlatformBrush, semantic_room)


func _bake_platform(brush: PlatformBrush, semantic_room: SemanticRoomData) -> void:
	var rect := brush.get_grid_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			var new_floor_cell = _create_cell(brush, cell)
			if !semantic_room.spatial_layers.add_cell(
				SpatialLayer.SpatialType.FLOOR, new_floor_cell
			):
				var issue = BakeIssue.new(
					BakeIssue.IssueType.BRUSH_OVERLAP,
					BakeIssue.Severity.ERROR,
					"Platform brushes overlap",
					cell
				)
				issue_found.emit(issue)


func _create_cell(brush: PlatformBrush, cell: Vector2i) -> SemanticSpatialFloorCell:
	var tile := SemanticSpatialFloorCell.new()
	if brush.has_trait(PlatformBrush.Trait.ONE_WAY):
		tile.traits.append(SemanticSpatialFloorCell.Trait.ONE_WAY)
	if brush.has_trait(PlatformBrush.Trait.BREAKABLE):
		tile.traits.append(SemanticSpatialFloorCell.Trait.BREAKABLE)
	tile.cell = cell
	return tile
