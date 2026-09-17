class_name DuplicateCellValidator
extends BakeValidator


func validate(context: RoomBakeContext) -> void:
	var validate_types: Array[SpatialLayer.SpatialType] = [
		SpatialLayer.SpatialType.FLOOR,
		SpatialLayer.SpatialType.WALL,
		SpatialLayer.SpatialType.BACKGROUND
	]
	for type in validate_types:
		_validate_type(type, context)


func _validate_type(type: SpatialLayer.SpatialType, context: RoomBakeContext) -> void:
	var room_data = context.semantic_data
	var layer_data = room_data.spatial_layers.get_cells(type)
	for cell in layer_data:
		if !_validate_cell(cell, layer_data):
			context.report.add_error(_create_issue(type, cell))


func _validate_cell(cell: SemanticSpatialCell, cells: Array[SemanticSpatialCell]) -> bool:
	var count: int = 0
	for item in cells:
		if item.cell == cell.cell:
			count += 1
		if count > 1:
			return false
	return true


func _create_issue(type: SpatialLayer.SpatialType, cell: SemanticSpatialCell) -> BakeIssue:
	return BakeIssue.new(
		BakeIssue.IssueType.BRUSH_OVERLAP,
		BakeIssue.Severity.ERROR,
		"Dublicate cell type " + SpatialLayer.SpatialType.keys()[type],
		cell.cell
	)
