class_name SaveRoomDataStep
extends BakeStep

# Rooms sub-path shared by every output root, so production and debug roots stay
# in sync instead of duplicating the literal.
const ROOMS_SUFFIX := "scenes/rooms"

# Production output root. Named so tests and the debug bake reference the same
# value instead of duplicating the literal.
const DEFAULT_OUTPUT_ROOT := "res://" + ROOMS_SUFFIX

# Debug output root. Keeps debug artifacts out of the tracked production
# directory so a debug bake cannot overwrite production room files. Built from the
# same shared suffix as DEFAULT_OUTPUT_ROOT so the two roots cannot diverge.
const DEBUG_OUTPUT_ROOT := "res://debug/" + ROOMS_SUFFIX

# Output root for baked room data. Tests override this to a "user://test_<suite>"
# root; the debug bake overrides it to `DEBUG_OUTPUT_ROOT`.
var output_root: String = DEFAULT_OUTPUT_ROOT




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
			"Failed to save room data to %s (error %s)" % [room_data_path, err]))

	if context.runtime_room != null:
		var runtime_path = room_dir.path_join("%s_runtime.tscn" % _get_room_filename(context.room))
		var packed_scene = PackedScene.new()
		packed_scene.pack(context.runtime_room)
		var err_scene = ResourceSaver.save(packed_scene, runtime_path)
		if err_scene != OK:
			context.report.add_error(_error(BakeIssue.IssueType.BAKE_FAILED,
				"Failed to save runtime room scene to %s (error %s)" % [runtime_path, err_scene]))

	return context


func _get_room_dir(room: Node) -> String:
	var filename = room.scene_file_path.get_file().get_basename()
	return "%s/%s" % [output_root, filename]


func _get_room_filename(room: Node) -> String:
	return room.scene_file_path.get_file().get_basename()


func _error(issue_type: BakeIssue.IssueType, message: String) -> BakeIssue:
	return BakeIssue.new(issue_type, BakeIssue.Severity.FATAL, message, Vector2i.ZERO)
