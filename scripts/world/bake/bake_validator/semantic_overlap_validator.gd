class_name SemanticOverlapValidator
extends BakeValidator


func validate(context: RoomBakeContext) -> void:
	_validate_two_layers(SpatialLayer.SpatialType.FLOOR, SpatialLayer.SpatialType.WALL, context)


func _validate_two_layers(
	type1: SpatialLayer.SpatialType, type2: SpatialLayer.SpatialType, context: RoomBakeContext
) -> void:
	var layer1 = context.semantic_data.spatial_layers.get_cells(type1)
	var layer2 = context.semantic_data.spatial_layers.get_cells(type2)
	for item in layer1:
		if !_validate_cell(item, layer2):
			context.report.add_error(_create_issue(type1, type2, item))


func _validate_cell(cell: SemanticSpatialCell, cells: Array[SemanticSpatialCell]) -> bool:
	for item in cells:
		if item.cell == cell.cell:
			return false
	return true


func _create_issue(
	type1: SpatialLayer.SpatialType, type2: SpatialLayer.SpatialType, cell: SemanticSpatialCell
) -> BakeIssue:
	var error_message: String = (
		"Overlap cells of types "
		+ SpatialLayer.SpatialType.keys()[type1]
		+ " and "
		+ SpatialLayer.SpatialType.keys()[type2]
	)
	return BakeIssue.new(
		BakeIssue.IssueType.BRUSH_OVERLAP, BakeIssue.Severity.ERROR, error_message, cell.cell
	)
