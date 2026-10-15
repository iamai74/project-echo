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

	var room_dir = _get_room_dir(context.room)
	DirAccess.make_dir_recursive_absolute(room_dir)

	var room_data_path = room_dir.path_join("%s_room_data.tres" % _get_room_filename(context.room))
	var err = ResourceSaver.save(context.runtime_room_data, room_data_path)
	if err != OK:
		context.report.add_error(_error(BakeIssue.IssueType.BAKE_FAILED,
			"Failed to save room data to %s (error %d)" % [room_data_path, err]))

	if context.runtime_room != null:
		var runtime_path = room_dir.path_join("%s_runtime.tscn" % _get_room_filename(context.room))
		var packed_scene = PackedScene.new()
		packed_scene.pack(context.runtime_room)
		var err_scene = ResourceSaver.save(packed_scene, runtime_path)
		if err_scene != OK:
			context.report.add_error(_error(BakeIssue.IssueType.BAKE_FAILED,
				"Failed to save runtime room scene to %s (error %d)" % [runtime_path, err_scene]))

	return context


func _get_room_dir(room: Node) -> String:
	var filename = room.scene_file_path.get_file().get_basename()
	return "res://scenes/rooms/%s" % filename


func _get_room_filename(room: Node) -> String:
	return room.scene_file_path.get_file().get_basename()


func _error(issue_type: BakeIssue.IssueType, message: String) -> BakeIssue:
	return BakeIssue.new(issue_type, BakeIssue.Severity.FATAL, message, Vector2i.ZERO)
