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

	# Populate the data the step serializes so the reload can assert real content.
	var platform_cell := SemanticCell.new()
	platform_cell.position = Vector2i(0, 0)
	context.runtime_room_data.platforms.append(platform_cell)
	var wall_cell := SemanticCell.new()
	wall_cell.position = Vector2i(1, 0)
	context.runtime_room_data.walls.append(wall_cell)

	step.run(context)

	# The happy path records no errors.
	assert_bool(context.report.is_has_fatal()).is_false()
	assert_bool(context.report.is_has_issues()).is_false()

	# Both artifacts must exist on disk, derived the same way the step writes them.
	var room_dir = step._get_room_dir(context.room)
	var data_path = room_dir.path_join("%s_room_data.tres" % step._get_room_filename(context.room))
	var runtime_path = room_dir.path_join("%s_runtime.tscn" % step._get_room_filename(context.room))
	assert_file(data_path).exists()
	assert_file(runtime_path).exists()

	# The saved RoomData must reload and keep the layer content that was saved.
	var loaded: RoomData = ResourceLoader.load(data_path)
	assert_object(loaded).is_not_null()
	assert_object(loaded).is_class("RoomData")
	assert_int(loaded.version).is_equal(1)
	assert_int(loaded.platforms.size()).is_equal(1)
	assert_int(loaded.platforms[0].position.x).is_equal(0)
	assert_int(loaded.platforms[0].position.y).is_equal(0)
	assert_int(loaded.walls.size()).is_equal(1)
	assert_int(loaded.walls[0].position.x).is_equal(1)
	assert_int(loaded.walls[0].position.y).is_equal(0)

	# The runtime scene must be saved and loadable. Its Semantic/Tiles structure
	# is verified by the integration suite
	# (test_saved_runtime_room_loads_with_expected_structure).
	var runtime_scene = load(runtime_path)
	assert_object(runtime_scene).is_not_null()


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
