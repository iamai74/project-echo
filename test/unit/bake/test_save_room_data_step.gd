## SaveRoomDataStep unit tests.
## Covers: null runtime data error, successful save, save failure reporting,
## filename and directory derivation.
## All saves go to a temporary user:// directory and are cleaned up afterwards.
extends GdUnitTestSuite


const TEMP_ROOT := "user://test_save_room_data_step"


func before_test() -> void:
	_remove_dir(TEMP_ROOT)
	DirAccess.make_dir_recursive_absolute(TEMP_ROOT)


func after_test() -> void:
	_remove_dir(TEMP_ROOT)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if entry != "." and entry != "..":
				var entry_path := path.path_join(entry)
				if dir.current_is_dir():
					_remove_dir(entry_path)
				else:
					DirAccess.remove_absolute(entry_path)
			entry = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _make_context_with_data() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	var room_data = RoomData.new()
	context.runtime_room_data = room_data
	return context


# ── Error path: null runtime data ─────────────────────────────────

func test_save_room_data_step_fatal_when_data_null() -> void:
	var step = SaveRoomDataStep.new()
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	# runtime_room_data is null by default

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
	var all = context.report.get_all_issues()
	assert_bool(all.has(BakeIssue.IssueType.SEVERE_DATA_LOSS)).is_true()


# ── Filename and directory derivation ─────────────────────────────

func test_save_room_data_step_derives_room_filename_from_scene_path() -> void:
	var step = SaveRoomDataStep.new()
	# Use the test fixture instead of the debug scene
	var room = auto_free(
		load("res://test/fixtures/test_room_scene.tscn")
		.instantiate()
	)

	assert_str(room.scene_file_path).is_equal(
		"res://test/fixtures/test_room_scene.tscn"
	)
	assert_str(step._get_room_filename(room)).is_equal("test_room_scene")


func test_save_room_data_step_derives_room_dir_from_scene_path() -> void:
	var step = SaveRoomDataStep.new()
	step.output_root = TEMP_ROOT
	var room = auto_free(
		load("res://test/fixtures/test_room_scene.tscn")
		.instantiate()
	)

	assert_str(step._get_room_dir(room)).is_equal(
		TEMP_ROOT.path_join("test_room_scene")
	)


# ── Successful save ───────────────────────────────────────────────

func test_save_room_data_step_saves_data_successfully() -> void:
	var step = SaveRoomDataStep.new()
	# Use the test fixture instead of the debug scene
	var room = auto_free(
		load("res://test/fixtures/test_room_scene.tscn")
		.instantiate()
	)

	# Set output root to a temporary directory for this test
	step.output_root = "user://test_save_room_data_step"

	var context = _make_context_with_data()
	context.room = room
	context.runtime_room = auto_free(Node2D.new())

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_bool(context.report.is_has_issues()).is_false()


func test_save_room_data_step_skips_scene_save_when_runtime_room_null() -> void:
	var step = SaveRoomDataStep.new()
	# Use the test fixture instead of the debug scene
	var room = auto_free(
		load("res://test/fixtures/test_room_scene.tscn")
		.instantiate()
	)

	var context = _make_context_with_data()
	context.room = room
	# runtime_room stays null

	step.run(context)

	# Should not error when runtime_room is null
	assert_bool(context.report.is_has_fatal()).is_false()


# ── Save failure reporting ───────────────────────────────────────

func test_save_room_data_step_identifies_save_error() -> void:
	var step = SaveRoomDataStep.new()
	step.output_root = TEMP_ROOT

	var context = _make_context_with_data()
	context.room = auto_free(
		load("res://test/fixtures/test_room_scene.tscn")
		.instantiate()
	)

	# Occupy the save path with a directory so ResourceSaver fails.
	var room_dir = step._get_room_dir(context.room)
	var data_path = room_dir.path_join("%s_room_data.tres" % step._get_room_filename(context.room))
	DirAccess.make_dir_recursive_absolute(data_path)

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
	var all = context.report.get_all_issues()
	assert_bool(all.has(BakeIssue.IssueType.BAKE_FAILED)).is_true()
