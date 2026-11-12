## CameraRig unit tests.
## Covers: zoom-aware clamping, target following and its no-op paths, target and room
## setters, room bounds detection from direct TileMapLayer children, TileMapLayer bounds
## conversion, and the target-resolution fallbacks.
extends GdUnitTestSuite

const CAMERA_RIG_SCENE_PATH := "res://scenes/camera_rig.tscn"
const DEFAULT_TILESET_PATH := "res://resources/themes/default/default_tileset.tres"
const VIEWPORT_WIDTH_SETTING := "display/window/size/viewport_width"
const VIEWPORT_HEIGHT_SETTING := "display/window/size/viewport_height"
const FAR_POSITION := Vector2(123.0, 456.0)
const PLATFORM_LAYER_OFFSET := Vector2(64.0, 64.0)


# --- _clamp: inside, each edge, no bounds, zoomed-in, room equal to the view ---


func test_clamp_parameters(case_name: String, zoom: Vector2, _test_parameters := [
	["inside", Vector2.ONE],
	["beyond_left", Vector2.ONE],
	["beyond_right", Vector2.ONE],
	["beyond_top", Vector2.ONE],
	["beyond_bottom", Vector2.ONE],
	["no_bounds", Vector2.ONE],
	["zoomed_in", Vector2(2.0, 2.0)],
	["room_equals_view", Vector2.ONE]
]) -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	rig.zoom = zoom

	var bounds := _room_bounds()
	var view := _view_size()
	var half := _half_view(zoom)

	if case_name != "no_bounds":
		rig.set_room_bounds(bounds)

	var pos: Vector2
	var expected: Vector2
	match case_name:
		"inside":
			pos = bounds.get_center()
			expected = pos
		"beyond_left":
			pos = Vector2(bounds.position.x - 500.0, bounds.get_center().y)
			expected = Vector2(bounds.position.x + half.x, pos.y)
		"beyond_right":
			pos = Vector2(bounds.end.x + 500.0, bounds.get_center().y)
			expected = Vector2(bounds.end.x - half.x, pos.y)
		"beyond_top":
			pos = Vector2(bounds.get_center().x, bounds.position.y - 500.0)
			expected = Vector2(pos.x, bounds.position.y + half.y)
		"beyond_bottom":
			pos = Vector2(bounds.get_center().x, bounds.end.y + 500.0)
			expected = Vector2(pos.x, bounds.end.y - half.y)
		"no_bounds":
			pos = Vector2(-500.0, -700.0)
			expected = pos
		"zoomed_in":
			pos = bounds.position + half * 0.5
			expected = bounds.position + half
		"room_equals_view":
			rig.set_room_bounds(Rect2(bounds.position, view))
			pos = Vector2(-500.0, 5000.0)
			expected = bounds.position + view * 0.5
		_:
			assert_bool(false).override_failure_message("Unknown clamp case: %s" % case_name).is_true()
			return

	var result := rig._clamp(pos)
	assert_vector(result).is_equal(expected)

	if case_name != "no_bounds":
		var clamped_bounds := rig.room_bounds
		assert_float(result.x).is_between(clamped_bounds.position.x + half.x, clamped_bounds.end.x - half.x)
		assert_float(result.y).is_between(clamped_bounds.position.y + half.y, clamped_bounds.end.y - half.y)


# --- _process: follow and no-op paths ---


func test_process_follows_valid_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	target.global_position = Vector2(400.0, 300.0)
	rig.follow_offset = Vector2(10.0, -20.0)
	rig.set_target(target)

	rig._process(0.016)

	assert_vector(rig.global_position).is_equal(Vector2(410.0, 280.0))


func test_process_clamps_follow_to_room_bounds() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	var bounds := _room_bounds()
	rig.set_room_bounds(bounds)
	rig.set_target(target)
	target.global_position = bounds.position - Vector2(500.0, 500.0)

	rig._process(0.016)

	assert_vector(rig.global_position).is_equal(bounds.position + _half_view(Vector2.ONE))


func test_process_does_nothing_when_disabled() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	rig.global_position = FAR_POSITION
	rig.enabled = false
	rig.set_room_bounds(_room_bounds())
	rig.set_target(target)
	target.global_position = _room_bounds().get_center()

	rig._process(0.016)

	assert_vector(rig.global_position).is_equal(FAR_POSITION)


func test_process_does_nothing_with_null_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	rig.global_position = FAR_POSITION
	rig.set_room_bounds(_room_bounds())

	rig._process(0.016)

	assert_vector(rig.global_position).is_equal(FAR_POSITION)


func test_process_does_nothing_with_freed_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	rig.global_position = FAR_POSITION
	rig.set_room_bounds(_room_bounds())
	var target := Node2D.new()
	rig.set_target(target)
	target.free()

	assert_bool(is_instance_valid(target)).is_false()

	rig._process(0.016)

	assert_vector(rig.global_position).is_equal(FAR_POSITION)


# --- Setter API ---


func test_set_target_assigns_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D

	rig.set_target(target)

	assert_object(rig.target).is_same(target)


func test_set_target_resolves_character_body_child() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var wrapper := auto_free(Node2D.new()) as Node2D
	var body := CharacterBody2D.new()
	body.name = "Body"
	wrapper.add_child(body)

	rig.set_target(wrapper)

	assert_object(rig.target).is_same(body)


func test_set_target_keeps_character_body_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var body := auto_free(CharacterBody2D.new()) as CharacterBody2D

	rig.set_target(body)

	assert_object(rig.target).is_same(body)


func test_set_target_null_keeps_target_null() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig

	rig.set_target(null)

	assert_object(rig.target).is_null()


func test_set_room_bounds_assigns_bounds() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var bounds := Rect2(32.0, 64.0, 640.0, 360.0)

	rig.set_room_bounds(bounds)

	assert_that(rig.room_bounds).is_equal(bounds)


func test_set_room_assigns_room_and_refreshes_bounds() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var room := _make_room_with_one_layer()

	rig.set_room(room)

	assert_object(rig.room).is_same(room)
	assert_that(rig.room_bounds).is_equal(_single_layer_bounds())


func test_set_room_skips_refresh_when_auto_detect_disabled() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var existing := Rect2(0.0, 0.0, 100.0, 100.0)
	var room := _make_room_with_one_layer()
	rig.auto_detect_bounds = false
	rig.set_room_bounds(existing)

	rig.set_room(room)

	assert_object(rig.room).is_same(room)
	assert_that(rig.room_bounds).is_equal(existing)


# --- detect_bounds_from_room / _resolve_room_node ---


func test_detect_bounds_from_room_merges_direct_layers() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var room := _make_room_with_two_layers()
	rig.set_room(room, false)
	assert_that(rig.room_bounds).is_equal(Rect2())

	rig.detect_bounds_from_room()

	assert_that(rig.room_bounds).is_equal(_merged_layer_bounds())


func test_detect_bounds_from_room_keeps_bounds_when_no_layers() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var existing := Rect2(16.0, 32.0, 320.0, 180.0)
	var room := auto_free(Node2D.new()) as Node2D
	room.name = "EmptyRoom"
	add_child(room)
	rig.set_room_bounds(existing)
	rig.set_room(room, false)

	rig.detect_bounds_from_room()

	assert_that(rig.room_bounds).is_equal(existing)


func test_detect_bounds_from_room_does_nothing_outside_tree_without_room() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig

	rig.detect_bounds_from_room()

	assert_that(rig.room_bounds).is_equal(Rect2())


func test_detect_bounds_from_room_uses_parent_when_room_is_unset() -> void:
	var room := _make_room_with_one_layer()
	var rig := CameraRig.new()
	rig.target = room
	room.add_child(rig)

	rig.detect_bounds_from_room()

	assert_that(rig.room_bounds).is_equal(_single_layer_bounds())


# --- _bounds_from_tile_map_layer ---


func test_bounds_from_tile_map_layer_returns_empty_rect_for_empty_layer() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var layer := _make_tile_map_layer("Tiles", Vector2.ZERO)
	auto_free(layer)

	assert_that(rig._bounds_from_tile_map_layer(layer)).is_equal(Rect2())


func test_bounds_from_tile_map_layer_returns_world_rect_for_used_cells() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var room := auto_free(Node2D.new()) as Node2D
	var layer := _make_tile_map_layer("Tiles", Vector2(64.0, 96.0))
	room.add_child(layer)
	add_child(room)
	layer.set_cell(Vector2i(1, 2), 0, Vector2i.ZERO)

	var tile_size := Vector2(_default_tileset().tile_size)
	var expected := Rect2(Vector2(64.0, 96.0) + tile_size * Vector2(1.0, 2.0), tile_size)

	assert_that(rig._bounds_from_tile_map_layer(layer)).is_equal(expected)


# --- _resolve_target / _resolve_target_body fallbacks ---


func test_resolve_target_uses_character_sibling() -> void:
	var character := auto_free(Node2D.new()) as Node2D
	character.name = "Character"
	add_child(character)
	var rig := auto_free(CameraRig.new()) as CameraRig
	rig.auto_detect_bounds = false

	add_child(rig)

	assert_object(rig.target).is_same(character)


func test_resolve_target_uses_character_body_sibling() -> void:
	var body := auto_free(CharacterBody2D.new()) as CharacterBody2D
	body.name = "Body"
	add_child(body)
	var rig := auto_free(CameraRig.new()) as CameraRig
	rig.auto_detect_bounds = false

	add_child(rig)

	assert_object(rig.target).is_same(body)


func test_resolve_target_does_nothing_outside_tree() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig

	rig._resolve_target()

	assert_object(rig.target).is_null()


func test_resolve_target_keeps_existing_target() -> void:
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	rig.target = target

	rig._resolve_target()

	assert_object(rig.target).is_same(target)


# --- _ready ---


func test_ready_creates_camera_and_follows_target() -> void:
	var rig := auto_free(load(CAMERA_RIG_SCENE_PATH).instantiate()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	target.global_position = Vector2(400.0, 300.0)
	rig.target = target
	rig.follow_offset = Vector2(10.0, -20.0)
	rig.auto_detect_bounds = false

	add_child(rig)

	var camera := rig.get_node_or_null("Camera2D") as Camera2D
	assert_object(camera).is_not_null()
	assert_bool(camera.is_current()).is_true()
	assert_int(camera.anchor_mode).is_equal(Camera2D.ANCHOR_MODE_DRAG_CENTER)
	assert_bool(camera.position_smoothing_enabled).is_false()
	assert_vector(camera.zoom).is_equal(rig.zoom)
	assert_vector(rig.global_position).is_equal(Vector2(410.0, 280.0))


func test_ready_auto_detects_room_bounds() -> void:
	var room := _make_room_with_one_layer()
	var rig := auto_free(CameraRig.new()) as CameraRig
	var target := auto_free(Node2D.new()) as Node2D
	rig.target = target
	rig.room = room

	add_child(rig)

	assert_that(rig.room_bounds).is_equal(_single_layer_bounds())


# --- Helpers ---


func _view_size() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting(VIEWPORT_WIDTH_SETTING),
		ProjectSettings.get_setting(VIEWPORT_HEIGHT_SETTING)
	)


func _half_view(zoom: Vector2) -> Vector2:
	return _view_size() / zoom * 0.5


func _room_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, _view_size() * 2.0)


func _default_tileset() -> TileSet:
	return load(DEFAULT_TILESET_PATH) as TileSet


func _single_layer_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(_default_tileset().tile_size))


func _merged_layer_bounds() -> Rect2:
	var tile_size := Vector2(_default_tileset().tile_size)
	var platform_bounds := Rect2(PLATFORM_LAYER_OFFSET + tile_size * Vector2(1.0, 1.0), tile_size)
	return _single_layer_bounds().merge(platform_bounds)


func _make_tile_map_layer(layer_name: String, layer_position: Vector2) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = _default_tileset()
	layer.position = layer_position
	return layer


func _make_room_with_one_layer() -> Node2D:
	var room := auto_free(Node2D.new()) as Node2D
	room.name = "Room"

	var layer := _make_tile_map_layer("Tiles", Vector2.ZERO)
	layer.set_cell(Vector2i(0, 0), 0, Vector2i.ZERO)
	room.add_child(layer)

	add_child(room)
	return room


func _make_room_with_two_layers() -> Node2D:
	var room := auto_free(Node2D.new()) as Node2D
	room.name = "Room"

	var floor_layer := _make_tile_map_layer("Floor", Vector2.ZERO)
	floor_layer.set_cell(Vector2i(0, 0), 0, Vector2i.ZERO)
	room.add_child(floor_layer)

	room.add_child(_make_tile_map_layer("Empty", Vector2.ZERO))

	var platform_layer := _make_tile_map_layer("Platforms", PLATFORM_LAYER_OFFSET)
	platform_layer.set_cell(Vector2i(1, 1), 0, Vector2i.ZERO)
	room.add_child(platform_layer)

	add_child(room)
	return room
