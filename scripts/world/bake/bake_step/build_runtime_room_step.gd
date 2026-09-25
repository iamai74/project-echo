class_name BuildRuntimeRoomStep
extends BakeStep


func get_id() -> StringName:
	return &"build_runtime_room"


func get_display_name() -> String:
	return "BuildRuntimeRoomStep"


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

	var data_builder = RoomDataBuilder.new()
	context.runtime_room_data = data_builder.build(context.semantic_data)

	var runtime_builder = RuntimeRoomBuilder.new()
	context.runtime_room = runtime_builder.build(context.runtime_room_data)

	return context
