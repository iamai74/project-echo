class_name MarkerPlacementValidator
extends BakeValidator


func validate(context: RoomBakeContext) -> void:
	if context == null or context.semantic_data == null:
		return

	var markers: Array[MarkerData] = context.semantic_data.markers.get_all_markers()
	var room_bounds: Rect2i = context.room_bounds
	var has_valid_bounds: bool = RoomBounds.has_area(room_bounds)
	var wall_positions: Dictionary = _collect_wall_positions(context)
	var type_count: int = MarkerType.Value.keys().size()

	var seen_ids: Dictionary = {}
	var seen_type_positions: Dictionary = {}

	for marker in markers:
		var type: int = int(marker.type)

		# 1. Type must be a known MarkerType. The raw value is reported so an
		# out-of-range integer stays visible in the message.
		if type < 0 or type >= type_count:
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, marker, "has invalid type")

		# 2. content_id must be set.
		if marker.content_id.is_empty():
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, marker, "has empty content_id")

		# 3. marker_id, when set, must be unique within the room.
		if not marker.marker_id.is_empty():
			if seen_ids.has(marker.marker_id):
				_report(
					context,
					BakeIssue.IssueType.SEMANTIC_CONFLICT,
					marker,
					"has a duplicate marker_id " + String(marker.marker_id)
				)
			seen_ids[marker.marker_id] = true

		# 4. Position must be inside the logical room bounds. Empty bounds is one
		# error per marker.
		if not has_valid_bounds:
			_report(
				context,
				BakeIssue.IssueType.SEMANTIC_CONFLICT,
				marker,
				"has invalid or empty logical room bounds"
			)
		elif not RoomBounds.contains_cell(room_bounds, marker.position):
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, marker, "is outside logical room bounds")

		# 5. Position must not sit inside a wall cell.
		if wall_positions.has(marker.position):
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, marker, "is inside a wall cell")

		# 6. Two markers may not share both type and position.
		var key := Vector3i(type, marker.position.x, marker.position.y)
		if seen_type_positions.has(key):
			_report(context, BakeIssue.IssueType.BRUSH_OVERLAP, marker, "has duplicate type and position")
		seen_type_positions[key] = true

	# 7. Marker brushes must be 1x1. Size is an authoring fact, not stored on MarkerData.
	_validate_marker_brush_size(context)


func _collect_wall_positions(context: RoomBakeContext) -> Dictionary:
	var wall_positions: Dictionary = {}
	for cell in context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL):
		wall_positions[cell.cell] = true
	return wall_positions


func _validate_marker_brush_size(context: RoomBakeContext) -> void:
	if context.brushes == null:
		return
	for brush in context.brushes.get_brushes(SemanticBrush.BrushType.MARKER):
		if brush == null or not brush.enabled:
			continue
		if brush.size == Vector2i.ONE:
			continue
		var position: Vector2i = brush.get_grid_position()
		context.report.add_error(
			BakeIssue.new(
				BakeIssue.IssueType.BRUSH_INVALID,
				BakeIssue.Severity.ERROR,
				"MARKER BRUSH at (" + str(position.x) + ", " + str(position.y) + ") is not 1x1",
				position
			)
		)


func _report(
	context: RoomBakeContext, issue_type: BakeIssue.IssueType, marker: MarkerData, suffix: String
) -> void:
	var position: Vector2i = marker.position
	var message: String = (
		"MARKER "
		+ MarkerType.name_of(marker.type)
		+ " at ("
		+ str(position.x)
		+ ", "
		+ str(position.y)
		+ ") "
		+ suffix
	)
	context.report.add_error(BakeIssue.new(issue_type, BakeIssue.Severity.ERROR, message, position))
