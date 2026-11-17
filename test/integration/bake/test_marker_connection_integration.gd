## Integration tests for the marker and connection point pipeline.
## Covers the complete authoring-to-RoomData-to-save-to-runtime contract:
## authored bounds, exact marker and connection data, disabled brushes,
## invalid data that still saves, bounds independence and theme independence.
extends GdUnitTestSuite


const TEMP_ROOT := "user://test_marker_connection_integration"
const TestTempDir = preload("res://test/fixtures/test_temp_dir.gd")
const ROOM_SCENE_PATH := "res://test/fixtures/test_room_scene.tscn"
const ROOM_NAME := "test_room_scene"
const ROOM_BOUNDS := Rect2i(0, 0, 8, 8)
const STANDARD_GEOMETRY_BOUNDS := Rect2i(0, 0, 8, 6)


func before_test() -> void:
	TestTempDir.remove(TEMP_ROOT)
	TestTempDir.create(TEMP_ROOT)


func after_test() -> void:
	TestTempDir.remove(TEMP_ROOT)


# ── Pipeline and room helpers ───────────────────────────────────────

func _make_steps() -> Array[BakeStep]:
	var registry := BakeProcessorRegistry.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, PlatformBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.WALL, WallBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.BACKGROUND, BackgroundBakeProcessor.new())

	var steps: Array[BakeStep] = [
		CollectBrushesStep.new(BrushCollector.new()),
		InitSemanticDataStep.new(),
		BakeSemanticLayerStep.new(registry),
		PostProcessStep.new(),
		BakeMarkersStep.new(),
		BakeConnectionsStep.new(),
		ValidateStep.new(),
		BuildRuntimeRoomStep.new(),
		ApplyDefaultThemeStep.new(),
	]
	return steps


func _make_pipeline_without_save() -> BakePipeline:
	return BakePipeline.new(_make_steps())


func _make_pipeline_with_save(output_root: String) -> BakePipeline:
	var steps := _make_steps()
	var save_step := SaveRoomDataStep.new()
	save_step.output_root = output_root
	steps.append(save_step)
	return BakePipeline.new(steps)


func _make_context(room: Node) -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.report = BakeReport.new()
	context.room = room
	return context


func _make_room(bounds: Rect2i) -> RoomAuthoring:
	var room := auto_free(RoomAuthoring.new()) as RoomAuthoring
	room.room_bounds = bounds
	return room


func _make_fixture_room(bounds: Rect2i) -> RoomAuthoring:
	var room := auto_free(load(ROOM_SCENE_PATH).instantiate()) as RoomAuthoring
	assert_object(room).is_not_null()
	room.room_bounds = bounds
	return room


func _pixel_position(cell: Vector2i) -> Vector2:
	var tile_size := World.settings.tile_size
	return Vector2(cell.x * tile_size, cell.y * tile_size)


func _add_platform(room: Node, cell: Vector2i, size: Vector2i) -> PlatformBrush:
	var brush := PlatformBrush.new()
	brush.position = _pixel_position(cell)
	brush.size = size
	room.add_child(brush)
	return brush


func _add_wall(room: Node, cell: Vector2i, size: Vector2i) -> WallBrush:
	var brush := WallBrush.new()
	brush.position = _pixel_position(cell)
	brush.size = size
	room.add_child(brush)
	return brush


func _add_background(room: Node, cell: Vector2i, size: Vector2i) -> BackgroundBrush:
	var brush := BackgroundBrush.new()
	brush.position = _pixel_position(cell)
	brush.size = size
	room.add_child(brush)
	return brush


func _add_marker(
	room: Node,
	cell: Vector2i,
	marker_type: MarkerType.Value,
	content_id: StringName,
	marker_id: StringName
) -> MarkerBrush:
	var brush := MarkerBrush.new()
	brush.position = _pixel_position(cell)
	brush.marker_type = marker_type
	brush.content_id = content_id
	brush.marker_id = marker_id
	room.add_child(brush)
	return brush


func _add_connection(
	room: Node,
	cell: Vector2i,
	size: Vector2i,
	side: ConnectionSide.Value,
	connection_id: StringName
) -> ConnectionPointBrush:
	var brush := ConnectionPointBrush.new()
	brush.position = _pixel_position(cell)
	brush.size = size
	brush.side = side
	brush.connection_id = connection_id
	room.add_child(brush)
	return brush


func _build_standard_room() -> RoomAuthoring:
	var room := _make_room(ROOM_BOUNDS)
	_populate_standard_room(room)
	return room


func _populate_standard_room(room: RoomAuthoring) -> void:
	# Wall perimeter around an 8x6 region with a three-cell gap on the top edge.
	_add_wall(room, Vector2i(0, 0), Vector2i(3, 1))
	_add_wall(room, Vector2i(6, 0), Vector2i(2, 1))
	_add_wall(room, Vector2i(0, 5), Vector2i(8, 1))
	_add_wall(room, Vector2i(0, 1), Vector2i(1, 4))
	_add_wall(room, Vector2i(7, 1), Vector2i(1, 4))
	# Platform floor inside the walls.
	_add_platform(room, Vector2i(1, 4), Vector2i(6, 1))
	# One enemy, one loot marker.
	_add_marker(
		room,
		Vector2i(2, 3),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"enemy_01"
	)
	_add_marker(
		room,
		Vector2i(5, 2),
		MarkerType.Value.LOOT_SPAWN,
		&"chest_gold",
		&"loot_01"
	)
	# One top connection covering the gap exactly.
	_add_connection(
		room,
		Vector2i(3, 0),
		Vector2i(3, 1),
		ConnectionSide.Value.TOP,
		&"top_gap"
	)


# ── Assertion helpers ───────────────────────────────────────────────

func _assert_runtime_structure(runtime_room: Node) -> TileMapLayer:
	assert_str(runtime_room.name).is_equal("RuntimeRoom")
	assert_int(runtime_room.get_child_count()).is_equal(1)
	var semantic := runtime_room.get_node_or_null("Semantic")
	assert_object(semantic).is_not_null()
	assert_int(semantic.get_child_count()).is_equal(1)
	var tiles := semantic.get_node_or_null("Tiles") as TileMapLayer
	assert_object(tiles).is_not_null()
	return tiles


func _has_issue(
	context: RoomBakeContext, severity: BakeIssue.Severity, fragment: String
) -> bool:
	var issues := context.report.get_all_issues()
	for type in issues:
		for item in issues[type]:
			var issue := item as BakeIssue
			if issue.severity == severity and issue.message.contains(fragment):
				return true
	return false


func _node_names(node: Node) -> Array[String]:
	var names: Array[String] = [String(node.name)]
	for child in node.get_children():
		names.append_array(_node_names(child))
	return names


func _used_cell_keys(tiles: TileMapLayer) -> Array[String]:
	var keys: Array[String] = []
	for cell in tiles.get_used_cells():
		keys.append("%d,%d" % [cell.x, cell.y])
	keys.sort()
	return keys


func _saved_data_path() -> String:
	return TEMP_ROOT.path_join(ROOM_NAME).path_join("%s_room_data.tres" % ROOM_NAME)


func _saved_runtime_path() -> String:
	return TEMP_ROOT.path_join(ROOM_NAME).path_join("%s_runtime.tscn" % ROOM_NAME)


# ── End-to-end authoring ────────────────────────────────────────────

func test_authored_markers_and_connections_reach_room_data_and_runtime() -> void:
	var context := _make_context(_build_standard_room())

	_make_pipeline_without_save().run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_int(context.runtime_room_data.version).is_equal(2)
	assert_bool(context.runtime_room_data.room_bounds == ROOM_BOUNDS).is_true()
	assert_bool(
		context.runtime_room_data.geometry_bounds == STANDARD_GEOMETRY_BOUNDS
	).is_true()

	assert_int(context.runtime_room_data.markers.size()).is_equal(2)
	var enemy: MarkerData = context.runtime_room_data.markers[0]
	assert_int(enemy.type).is_equal(MarkerType.Value.ENEMY_SPAWN)
	assert_vector(enemy.position).is_equal(Vector2i(2, 3))
	assert_str(enemy.content_id).is_equal(&"enemy_goblin")
	assert_str(enemy.marker_id).is_equal(&"enemy_01")
	var loot: MarkerData = context.runtime_room_data.markers[1]
	assert_int(loot.type).is_equal(MarkerType.Value.LOOT_SPAWN)
	assert_vector(loot.position).is_equal(Vector2i(5, 2))
	assert_str(loot.content_id).is_equal(&"chest_gold")
	assert_str(loot.marker_id).is_equal(&"loot_01")

	assert_int(context.runtime_room_data.connections.size()).is_equal(1)
	var connection: ConnectionData = context.runtime_room_data.connections[0]
	assert_str(connection.id).is_equal(&"top_gap")
	assert_int(connection.side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(connection.position).is_equal(Vector2i(3, 0))
	assert_vector(connection.size).is_equal(Vector2i(3, 1))

	var tiles := _assert_runtime_structure(context.runtime_room)
	assert_int(tiles.get_used_cells().size()).is_greater(0)
	auto_free(context.runtime_room)


# ── Bounds independence ─────────────────────────────────────────────

func test_room_bounds_stay_fixed_when_geometry_changes() -> void:
	var bounds := Rect2i(0, 0, 10, 10)

	var first_room := _make_room(bounds)
	_add_platform(first_room, Vector2i(2, 2), Vector2i(4, 1))
	var first_context := _make_context(first_room)
	_make_pipeline_without_save().run(first_context)
	assert_bool(first_context.report.is_has_fatal()).is_false()
	auto_free(first_context.runtime_room)

	# Remove one platform cell away from the room edge; only geometry shrinks.
	var second_room := _make_room(bounds)
	_add_platform(second_room, Vector2i(2, 2), Vector2i(3, 1))
	var second_context := _make_context(second_room)
	_make_pipeline_without_save().run(second_context)
	assert_bool(second_context.report.is_has_fatal()).is_false()
	auto_free(second_context.runtime_room)

	assert_bool(first_context.runtime_room_data.room_bounds == bounds).is_true()
	assert_bool(second_context.runtime_room_data.room_bounds == bounds).is_true()
	assert_bool(
		first_context.runtime_room_data.geometry_bounds == Rect2i(2, 2, 4, 1)
	).is_true()
	assert_bool(
		second_context.runtime_room_data.geometry_bounds == Rect2i(2, 2, 3, 1)
	).is_true()
	assert_bool(
		first_context.runtime_room_data.geometry_bounds
		!= second_context.runtime_room_data.geometry_bounds
	).is_true()


# ── Save and reload ─────────────────────────────────────────────────

func test_full_pipeline_saves_and_reloads_markers_and_connections() -> void:
	var room := _make_fixture_room(ROOM_BOUNDS)
	_populate_standard_room(room)
	var context := _make_context(room)

	_make_pipeline_with_save(TEMP_ROOT).run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	auto_free(context.runtime_room)
	assert_file(_saved_data_path()).exists()
	assert_file(_saved_runtime_path()).exists()

	var loaded: RoomData = ResourceLoader.load(_saved_data_path())
	assert_object(loaded).is_not_null()
	assert_int(loaded.version).is_equal(2)
	assert_bool(loaded.room_bounds == ROOM_BOUNDS).is_true()
	assert_bool(loaded.geometry_bounds == STANDARD_GEOMETRY_BOUNDS).is_true()

	assert_int(loaded.markers.size()).is_equal(2)
	var enemy: MarkerData = loaded.markers[0]
	assert_int(enemy.type).is_equal(MarkerType.Value.ENEMY_SPAWN)
	assert_vector(enemy.position).is_equal(Vector2i(2, 3))
	assert_str(enemy.content_id).is_equal(&"enemy_goblin")
	assert_str(enemy.marker_id).is_equal(&"enemy_01")
	var loot: MarkerData = loaded.markers[1]
	assert_int(loot.type).is_equal(MarkerType.Value.LOOT_SPAWN)
	assert_vector(loot.position).is_equal(Vector2i(5, 2))
	assert_str(loot.content_id).is_equal(&"chest_gold")
	assert_str(loot.marker_id).is_equal(&"loot_01")

	assert_int(loaded.connections.size()).is_equal(1)
	var connection: ConnectionData = loaded.connections[0]
	assert_str(connection.id).is_equal(&"top_gap")
	assert_int(connection.side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(connection.position).is_equal(Vector2i(3, 0))
	assert_vector(connection.size).is_equal(Vector2i(3, 1))

	var runtime_room: Node = auto_free(load(_saved_runtime_path()).instantiate())
	var tiles := _assert_runtime_structure(runtime_room)
	assert_int(tiles.get_used_cells().size()).is_greater(0)


# ── Runtime structure ───────────────────────────────────────────────

func test_saved_runtime_scene_has_no_marker_or_connection_nodes() -> void:
	var room := _make_fixture_room(ROOM_BOUNDS)
	_populate_standard_room(room)
	var context := _make_context(room)

	_make_pipeline_with_save(TEMP_ROOT).run(context)
	assert_bool(context.report.is_has_fatal()).is_false()
	auto_free(context.runtime_room)

	var runtime_room: Node = auto_free(load(_saved_runtime_path()).instantiate())
	_assert_runtime_structure(runtime_room)

	for node_name in _node_names(runtime_room):
		var lowered := node_name.to_lower()
		assert_bool(lowered.contains("marker")).is_false()
		assert_bool(lowered.contains("connection")).is_false()


# ── Disabled brushes ────────────────────────────────────────────────

func test_disabled_brushes_are_collected_but_never_baked() -> void:
	var room := _make_room(ROOM_BOUNDS)
	var platform := _add_platform(room, Vector2i(1, 1), Vector2i.ONE)
	platform.enabled = false
	var wall := _add_wall(room, Vector2i(2, 1), Vector2i.ONE)
	wall.enabled = false
	var background := _add_background(room, Vector2i(3, 1), Vector2i.ONE)
	background.enabled = false
	var marker := _add_marker(
		room,
		Vector2i(4, 2),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"enemy_01"
	)
	marker.enabled = false
	var connection := _add_connection(
		room,
		Vector2i(2, 0),
		Vector2i(1, 1),
		ConnectionSide.Value.TOP,
		&"disabled_exit"
	)
	connection.enabled = false

	var context := _make_context(room)
	_make_pipeline_without_save().run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	# The collector still sees every authored brush so the scene stays inspectable.
	assert_int(context.brushes.get_all_brushes().size()).is_equal(5)
	# None of them contributes semantic or gameplay data.
	assert_int(context.runtime_room_data.platforms.size()).is_zero()
	assert_int(context.runtime_room_data.walls.size()).is_zero()
	assert_int(context.runtime_room_data.background.size()).is_zero()
	assert_int(context.runtime_room_data.markers.size()).is_zero()
	assert_int(context.runtime_room_data.connections.size()).is_zero()
	assert_bool(context.runtime_room_data.geometry_bounds.has_area()).is_false()
	auto_free(context.runtime_room)


# ── Invalid data still saves ────────────────────────────────────────

func test_invalid_connection_reports_error_and_still_saves() -> void:
	var room := _make_fixture_room(ROOM_BOUNDS)
	_add_wall(room, Vector2i(2, 0), Vector2i.ONE)
	_add_connection(
		room,
		Vector2i(2, 0),
		Vector2i(1, 1),
		ConnectionSide.Value.TOP,
		&"blocked_exit"
	)
	var context := _make_context(room)

	_make_pipeline_with_save(TEMP_ROOT).run(context)

	# The pipeline reports the invalid connection but never upgrades it to fatal
	# and never repairs the authored data.
	assert_bool(context.report.is_has_fatal()).is_false()
	assert_bool(
		_has_issue(context, BakeIssue.Severity.ERROR, "overlaps wall cell")
	).is_true()
	assert_object(context.runtime_room_data).is_not_null()
	assert_int(context.runtime_room_data.connections.size()).is_equal(1)
	assert_str(context.runtime_room_data.connections[0].id).is_equal(&"blocked_exit")
	assert_object(context.runtime_room).is_not_null()
	auto_free(context.runtime_room)

	assert_file(_saved_data_path()).exists()
	assert_file(_saved_runtime_path()).exists()
	var loaded: RoomData = ResourceLoader.load(_saved_data_path())
	assert_object(loaded).is_not_null()
	assert_int(loaded.connections.size()).is_equal(1)
	assert_str(loaded.connections[0].id).is_equal(&"blocked_exit")
	assert_int(loaded.connections[0].side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(loaded.connections[0].position).is_equal(Vector2i(2, 0))


# ── Empty bounds on a plain root ────────────────────────────────────

func test_plain_node_root_reports_empty_bounds_instead_of_inferring_them() -> void:
	var room: Node2D = auto_free(Node2D.new())
	_add_platform(room, Vector2i(0, 0), Vector2i.ONE)
	_add_marker(
		room,
		Vector2i(1, 0),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"enemy_01"
	)

	var context := _make_context(room)
	_make_pipeline_without_save().run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_bool(
		_has_issue(context, BakeIssue.Severity.ERROR, "invalid or empty logical room bounds")
	).is_true()
	assert_bool(context.runtime_room_data.room_bounds == Rect2i()).is_true()
	assert_bool(
		context.runtime_room_data.geometry_bounds == Rect2i(0, 0, 1, 1)
	).is_true()
	auto_free(context.runtime_room)


# ── Theme ignores markers and connections ───────────────────────────

func test_theme_output_depends_only_on_spatial_data() -> void:
	var first_room := _make_room(ROOM_BOUNDS)
	_add_platform(first_room, Vector2i(1, 4), Vector2i(3, 1))
	_add_wall(first_room, Vector2i(1, 1), Vector2i(2, 1))
	_add_marker(
		first_room,
		Vector2i(3, 2),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"enemy_01"
	)
	_add_connection(
		first_room,
		Vector2i(2, 0),
		Vector2i(1, 1),
		ConnectionSide.Value.TOP,
		&"first_exit"
	)
	var first_context := _make_context(first_room)
	_make_pipeline_without_save().run(first_context)
	assert_bool(first_context.report.is_has_fatal()).is_false()

	var second_room := _make_room(ROOM_BOUNDS)
	_add_platform(second_room, Vector2i(1, 4), Vector2i(3, 1))
	_add_wall(second_room, Vector2i(1, 1), Vector2i(2, 1))
	_add_marker(
		second_room,
		Vector2i(4, 2),
		MarkerType.Value.LOOT_SPAWN,
		&"chest_gold",
		&"loot_01"
	)
	_add_marker(
		second_room,
		Vector2i(5, 3),
		MarkerType.Value.CHECKPOINT,
		&"checkpoint_a",
		&"checkpoint_01"
	)
	_add_connection(
		second_room,
		Vector2i(5, 0),
		Vector2i(2, 1),
		ConnectionSide.Value.TOP,
		&"second_exit"
	)
	var second_context := _make_context(second_room)
	_make_pipeline_without_save().run(second_context)
	assert_bool(second_context.report.is_has_fatal()).is_false()

	var first_tiles := _assert_runtime_structure(first_context.runtime_room)
	var second_tiles := _assert_runtime_structure(second_context.runtime_room)
	var first_keys := _used_cell_keys(first_tiles)
	assert_int(first_keys.size()).is_greater(0)
	assert_array(first_keys).is_equal(_used_cell_keys(second_tiles))

	auto_free(first_context.runtime_room)
	auto_free(second_context.runtime_room)
