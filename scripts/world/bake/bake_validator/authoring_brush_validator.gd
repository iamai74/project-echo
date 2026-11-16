class_name AuthoringBrushValidator
extends BakeValidator


func validate(context: RoomBakeContext) -> void:
	if context.brushes == null:
		return
	for brush in context.brushes.get_all_brushes():
		_check_brush(brush, context)


func _check_brush(brush: SemanticBrush, context: RoomBakeContext) -> void:
	if brush == null:
		return
	if not brush.enabled:
		return

	var type: SemanticBrush.BrushType = brush.get_brush_type()
	if type == SemanticBrush.BrushType.UNKNOWN:
		context.report.add_warning(
			_create_issue(
				BakeIssue.Severity.WARNING,
				"BRUSH " + SemanticBrush.BrushType.keys()[type] + " is not a baked brush type",
				brush.get_grid_position()
			)
		)
		return

	if not brush.is_grid_aligned():
		context.report.add_error(
			_create_issue(
				BakeIssue.Severity.ERROR,
				"BRUSH " + SemanticBrush.BrushType.keys()[type] + " is not grid aligned",
				brush.get_grid_position()
			)
		)


func _create_issue(
	severity: BakeIssue.Severity, message: String, position: Vector2i
) -> BakeIssue:
	var full_message: String = (
		message
		+ " at ("
		+ str(position.x)
		+ ", "
		+ str(position.y)
		+ ")"
	)
	return BakeIssue.new(BakeIssue.IssueType.BRUSH_INVALID, severity, full_message, position)
