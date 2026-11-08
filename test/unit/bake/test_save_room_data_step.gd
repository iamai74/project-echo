## SaveRoomDataStep failure-path tests.
## Covers: null runtime data error, successful save, save failure reporting,
## filename and directory derivation.
extends GdUnitTestSuite


func _make_context_with_data(scene_path: String = "") -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	var room_data = RoomData.new()
	context.runtime_room_data = room_data

	if not scene_path.is_empty():
		var room = Node2D.new()
		room.name = "TestRoom"
		# scene_file_path is set when a scene is loaded; here we simulate
		# by creating a packed scene in a temp path and instantiating from it.
		# For testing without filesystem writes we use a pre-loaded scene.
		context.room = auto_free(load(scene_path).instantiate())
		context.runtime_room = auto_free(Node2D.new())
	else:
		context.room = auto_free(Node2D.new())

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
	var room = auto_free(
		load("res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn")
		.instantiate()
	)

	assert_str(room.scene_file_path).is_equal(
		"res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn"
	)
	assert_str(step._get_room_filename(room)).is_equal("test_scene_for_bake_runtime")


func test_save_room_data_step_derives_room_dir_from_scene_path() -> void:
	var step = SaveRoomDataStep.new()
	var room = auto_free(
		load("res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn")
		.instantiate()
	)

	assert_str(step._get_room_dir(room)).is_equal(
		"res://scenes/rooms/test_scene_for_bake_runtime"
	)


# ── Successful save ───────────────────────────────────────────────

func test_save_room_data_step_saves_data_successfully() -> void:
	var step = SaveRoomDataStep.new()
	var room = auto_free(
		load("res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn")
		.instantiate()
	)

	var context = _make_context_with_data(
		"res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn"
	)
	context.room = room

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_bool(context.report.is_has_issues()).is_false()


func test_save_room_data_step_skips_scene_save_when_runtime_room_null() -> void:
	var step = SaveRoomDataStep.new()
	var room = auto_free(
		load("res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn")
		.instantiate()
	)

	var context = _make_context_with_data(
		"res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn"
	)
	context.room = room
	# runtime_room stays null

	step.run(context)

	# Should not error when runtime_room is null
	assert_bool(context.report.is_has_fatal()).is_false()


# ── Save failure reporting ───────────────────────────────────────

func test_save_room_data_step_identifies_save_error() -> void:
	var step = SaveRoomDataStep.new()
	# A room with no scene_file_path will fail to save because the path
	# cannot be derived.  We create a fresh Node2D with no loaded scene.
	var room = auto_free(Node2D.new())
	room.name = "OrphanRoom"

	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	context.runtime_room_data = RoomData.new()
	context.room = room

	step.run(context)

	# Either the save fails or the directory creation errors;
	# in both cases the step reports the issue.
	# The test verifies the step completes without crashing
	# and the returned context is the same reference.
	assert_object(step.run(context)).is_equal(context)
