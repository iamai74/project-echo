class_name BakeConnectionsStep
extends BakeStep


func get_id() -> StringName:
	return &"bake_connections"


func get_display_name() -> String:
	return "BakeConnectionsStep"


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

	var connections: Array[ConnectionData] = []
	var connection_brushes = context.brushes.get_brushes(SemanticBrush.BrushType.CONNECTION_POINT)
	for brush in connection_brushes:
		if not brush.enabled:
			continue
		var connection_brush: ConnectionPointBrush = brush as ConnectionPointBrush
		if connection_brush == null:
			var issue = BakeIssue.new(
				BakeIssue.IssueType.BAKE_FAILED,
				BakeIssue.Severity.FATAL,
				"Brush is not a connection point brush",
				brush.get_grid_position()
			)
			context.report.add_error(issue)
			continue

		var connection = ConnectionData.new()
		connection.id = connection_brush.connection_id
		connection.side = connection_brush.side
		connection.position = connection_brush.get_grid_position()
		connection.size = connection_brush.get_grid_size()
		connections.append(connection)

	connections.sort_custom(_connections_before)
	context.semantic_data.connections.append_array(connections)

	return context


func _connections_before(a: ConnectionData, b: ConnectionData) -> bool:
	if a.side != b.side:
		return a.side < b.side
	if a.position.y != b.position.y:
		return a.position.y < b.position.y
	if a.position.x != b.position.x:
		return a.position.x < b.position.x
	if a.size.x != b.size.x:
		return a.size.x < b.size.x
	if a.size.y != b.size.y:
		return a.size.y < b.size.y
	return String(a.id) < String(b.id)
