class_name BakeMarkersStep
extends BakeStep


func get_id() -> StringName:
	return &"bake_markers"


func get_display_name() -> String:
	return "BakeMarkersStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	if context.semantic_data == null:
		var issue = BakeIssue.new(
			BakeIssue.IssueType.SEVERE_DATA_LOSS,
			BakeIssue.Severity.FATAL,
			"Semantic data is empty",
			Vector2i.ZERO
		)
		context.report.add_error(issue)
		return context

	if context.brushes == null:
		var issue = BakeIssue.new(
			BakeIssue.IssueType.BAKE_FAILED,
			BakeIssue.Severity.FATAL,
			"Brush collection is empty",
			Vector2i.ZERO
		)
		context.report.add_error(issue)
		return context

	var marker_brushes = context.brushes.get_brushes(SemanticBrush.BrushType.MARKER)
	for brush in marker_brushes:
		if not brush.enabled:
			continue
		var marker_brush: MarkerBrush = brush as MarkerBrush
		if marker_brush == null:
			var issue = BakeIssue.new(
				BakeIssue.IssueType.BAKE_FAILED,
				BakeIssue.Severity.FATAL,
				"Brush is not a marker brush",
				brush.get_grid_position()
			)
			context.report.add_error(issue)
			continue

		var marker = MarkerData.new()
		marker.type = marker_brush.marker_type
		marker.position = marker_brush.get_grid_position()
		marker.content_id = marker_brush.content_id
		marker.marker_id = marker_brush.marker_id
		context.semantic_data.markers.add_marker(marker_brush.marker_type, marker)

	return context
