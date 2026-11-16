class_name ConnectionPointValidator
extends BakeValidator


func validate(context: RoomBakeContext) -> void:
	if context == null or context.semantic_data == null:
		return

	var connections: Array[ConnectionData] = context.semantic_data.connections
	if connections.is_empty():
		return

	var room_bounds: Rect2i = context.room_bounds
	var blocked_positions: Dictionary = _collect_blocked_positions(context)
	var side_count: int = ConnectionSide.Value.keys().size()
	var seen_ids: Dictionary = {}

	for connection in connections:
		var side: int = int(connection.side)
		var size: Vector2i = connection.size

		# 1. Side must be a known ConnectionSide. An unknown side makes the
		# side-dependent checks meaningless, so skip them.
		if side < 0 or side >= side_count:
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has invalid side")
		# 2. Size must be at least one cell on each axis.
		elif size.x < 1 or size.y < 1:
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has invalid size")
		else:
			_validate_geometry(context, connection, side, room_bounds, blocked_positions)

		# 3. The id must be set and unique within the room.
		_validate_id(context, connection, seen_ids)

	# 4. No two connections may share cells.
	_validate_pairwise_overlap(context, connections)


func _validate_geometry(
	context: RoomBakeContext,
	connection: ConnectionData,
	side: int,
	room_bounds: Rect2i,
	blocked_positions: Dictionary
) -> void:
	_validate_orientation(context, connection, side)
	if not _validate_placement(context, connection, side, room_bounds):
		return
	_validate_spatial_overlap(context, connection, blocked_positions)


func _validate_orientation(context: RoomBakeContext, connection: ConnectionData, side: int) -> void:
	if side == ConnectionSide.Value.TOP or side == ConnectionSide.Value.BOTTOM:
		if connection.size.y != 1:
			_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has invalid orientation")
	elif connection.size.x != 1:
		_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has invalid orientation")


func _validate_placement(
	context: RoomBakeContext, connection: ConnectionData, side: int, room_bounds: Rect2i
) -> bool:
	if not RoomBounds.has_area(room_bounds):
		_report(
			context,
			BakeIssue.IssueType.SEMANTIC_CONFLICT,
			connection,
			"has invalid or empty logical room bounds"
		)
		return false
	if not RoomBounds.contains_rect(room_bounds, Rect2i(connection.position, connection.size)):
		_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "is outside logical room bounds")
		return false
	if not _touches_edge(connection, side, room_bounds):
		_report(
			context,
			BakeIssue.IssueType.SEMANTIC_CONFLICT,
			connection,
			"does not touch the " + ConnectionSide.name_of(side).to_lower() + " room edge"
		)
	return true


func _validate_id(context: RoomBakeContext, connection: ConnectionData, seen_ids: Dictionary) -> void:
	if connection.id.is_empty():
		_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has empty id")
		return
	if seen_ids.has(connection.id):
		_report(context, BakeIssue.IssueType.SEMANTIC_CONFLICT, connection, "has a duplicate id")
	seen_ids[connection.id] = true


func _validate_spatial_overlap(
	context: RoomBakeContext, connection: ConnectionData, blocked_positions: Dictionary
) -> void:
	var rect := Rect2i(connection.position, connection.size)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if blocked_positions.has(cell):
				_report(
					context,
					BakeIssue.IssueType.SEMANTIC_CONFLICT,
					connection,
					"overlaps " + String(blocked_positions[cell]) + " cell (" + str(x) + ", " + str(y) + ")"
				)


func _validate_pairwise_overlap(context: RoomBakeContext, connections: Array[ConnectionData]) -> void:
	var count: int = connections.size()
	for i in range(count):
		var first: ConnectionData = connections[i]
		if not _has_valid_size(first):
			continue
		var first_rect := Rect2i(first.position, first.size)
		for j in range(i + 1, count):
			var second: ConnectionData = connections[j]
			if not _has_valid_size(second):
				continue
			if first_rect.intersects(Rect2i(second.position, second.size)):
				context.report.add_error(
					BakeIssue.new(
						BakeIssue.IssueType.BRUSH_OVERLAP,
						BakeIssue.Severity.ERROR,
						"CONNECTION " + _identity(first) + " overlaps connection " + _identity(second),
						first.position
					)
				)


func _has_valid_size(connection: ConnectionData) -> bool:
	return connection.size.x >= 1 and connection.size.y >= 1


func _touches_edge(connection: ConnectionData, side: int, room_bounds: Rect2i) -> bool:
	match side:
		ConnectionSide.Value.TOP:
			return connection.position.y == room_bounds.position.y
		ConnectionSide.Value.BOTTOM:
			return connection.position.y + connection.size.y == room_bounds.end.y
		ConnectionSide.Value.LEFT:
			return connection.position.x == room_bounds.position.x
		ConnectionSide.Value.RIGHT:
			return connection.position.x + connection.size.x == room_bounds.end.x
	return false


func _collect_blocked_positions(context: RoomBakeContext) -> Dictionary:
	var blocked: Dictionary = {}
	for cell in context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL):
		blocked[cell.cell] = "wall"
	for cell in context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM):
		blocked[cell.cell] = "platform"
	return blocked


func _report(
	context: RoomBakeContext, issue_type: BakeIssue.IssueType, connection: ConnectionData, suffix: String
) -> void:
	var position: Vector2i = connection.position
	var message: String = "CONNECTION "
	if not connection.id.is_empty():
		message += String(connection.id) + " "
	message += ConnectionSide.name_of(int(connection.side))
	message += " at (" + str(position.x) + ", " + str(position.y) + ") " + suffix
	context.report.add_error(BakeIssue.new(issue_type, BakeIssue.Severity.ERROR, message, position))


func _identity(connection: ConnectionData) -> String:
	if not connection.id.is_empty():
		return String(connection.id)
	return "(" + str(connection.position.x) + ", " + str(connection.position.y) + ")"
