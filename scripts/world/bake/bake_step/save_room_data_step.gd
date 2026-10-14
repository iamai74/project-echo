class_name SaveRoomDataStep
extends BakeStep


func get_id() -> StringName:
	return &"save_room_data"


func get_display_name() -> String:
	return "SaveRoomDataStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	if context.runtime_room_data == null:
		context.report.add_error(_error(BakeIssue.IssueType.SEVERE_DATA_LOSS,
			"Runtime room data is null, cannot save"))
		return context

	var save_path = _get_save_path(context.room)
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())

	var err = ResourceSaver.save(context.runtime_room_data, save_path)
	if err != OK:
		context.report.add_error(_error(BakeIssue.IssueType.BAKE_FAILED,
			"Failed to save room data to %s (error %d)" % [save_path, err]))

	return context


func _get_save_path(room: Node) -> String:
	var filename = room.scene_file_path.get_file().get_basename()
	return "res://scenes/rooms/%s/%s_room_data.tres" % [filename, filename]


func _error(issue_type: BakeIssue.IssueType, message: String) -> BakeIssue:
	return BakeIssue.new(issue_type, BakeIssue.Severity.FATAL, message, Vector2i.ZERO)
