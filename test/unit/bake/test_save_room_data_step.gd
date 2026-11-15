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

	# Version 2 bounds and marker/connection content that must survive a round trip.
	context.runtime_room_data.version = 2
	context.runtime_room_data.room_bounds = Rect2i(0, 0, 8, 6)
	context.runtime_room_data.geometry_bounds = Rect2i(0, 0, 2, 1)
	var marker := MarkerData.new()
	marker.type = MarkerType.Value.ENEMY_SPAWN
	marker.position = Vector2i(3, 4)
	marker.content_id = &"enemy_goblin"
	marker.marker_id = &"spawn_01"
	context.runtime_room_data.markers.append(marker)
	var connection := ConnectionData.new()
	connection.id = &"main_exit"
	connection.side = ConnectionSide.Value.BOTTOM
	connection.position = Vector2i(4, 5)
	connection.size = Vector2i(2, 1)
	context.runtime_room_data.connections.append(connection)

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

	# The saved RoomData must reload and keep the content that was saved.
	var loaded: RoomData = ResourceLoader.load(data_path)
	assert_object(loaded).is_not_null()
	assert_object(loaded).is_class("RoomData")
	# A freshly baked resource is version 2, never the legacy version 1.
	assert_int(loaded.version).is_equal(2)
	assert_int(loaded.room_bounds.size.x).is_equal(8)
	assert_int(loaded.room_bounds.size.y).is_equal(6)
	assert_int(loaded.geometry_bounds.size.x).is_equal(2)
	assert_int(loaded.geometry_bounds.size.y).is_equal(1)
	assert_int(loaded.platforms.size()).is_equal(1)
	assert_int(loaded.platforms[0].position.x).is_equal(0)
	assert_int(loaded.platforms[0].position.y).is_equal(0)
	assert_int(loaded.walls.size()).is_equal(1)
	assert_int(loaded.walls[0].position.x).is_equal(1)
	assert_int(loaded.walls[0].position.y).is_equal(0)
	# Markers and connections round-trip through the saved resource.
	assert_int(loaded.markers.size()).is_equal(1)
	assert_int(loaded.markers[0].type).is_equal(MarkerType.Value.ENEMY_SPAWN)
	assert_vector(loaded.markers[0].position).is_equal(Vector2i(3, 4))
	assert_str(loaded.markers[0].content_id).is_equal(&"enemy_goblin")
	assert_str(loaded.markers[0].marker_id).is_equal(&"spawn_01")
	assert_int(loaded.connections.size()).is_equal(1)
	assert_str(loaded.connections[0].id).is_equal(&"main_exit")
	assert_int(loaded.connections[0].side).is_equal(ConnectionSide.Value.BOTTOM)
	assert_vector(loaded.connections[0].position).is_equal(Vector2i(4, 5))
	assert_vector(loaded.connections[0].size).is_equal(Vector2i(2, 1))
	# A version 2 resource must never serialize the legacy bounds property.
	var property_names: Array[StringName] = []
	for property in loaded.get_property_list():
		property_names.append(property.name)
	assert_bool(property_names.has(&"bounds")).is_false()
	var data_text := FileAccess.get_file_as_string(data_path)
	assert_bool(data_text.contains("\nbounds = ")).is_false()

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


# ── Version 1 compatibility ──────────────────────────────────────

func test_legacy_version1_resource_loads_with_geometry_bounds() -> void:
	# A version 1 artifact serialized only the geometry-derived `bounds` property
	# and no version 2 fields. Loading it must capture the legacy property without
	# fabricating logical room bounds.
	var legacy_path := TEMP_ROOT.path_join("legacy_room_data.tres")
	var file := FileAccess.open(legacy_path, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(
		'[gd_resource type="Resource" script_class="RoomData" format=3]\n'
		+ '\n'
		+ '[ext_resource type="Script" path="res://scripts/world/bake/semantic_data/room_data.gd"'
		+ ' id="1_room"]\n'
		+ '\n'
		+ "[resource]\n"
		+ 'script = ExtResource("1_room")\n'
		+ "bounds = Rect2i(2, 3, 4, 5)\n"
	)
	file.close()

	var loaded: RoomData = ResourceLoader.load(legacy_path)
	assert_object(loaded).is_not_null()
	assert_int(loaded.version).is_equal(1)
	assert_bool(loaded.geometry_bounds == Rect2i(2, 3, 4, 5)).is_true()
	assert_bool(loaded.room_bounds == Rect2i()).is_true()
	assert_int(loaded.markers.size()).is_zero()
	assert_int(loaded.connections.size()).is_zero()


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
