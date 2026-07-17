extends Node2D
class_name CameraRig

@export var target: Node2D
@export var enabled: bool = true
@export_group("Follow")
@export var follow_offset: Vector2 = Vector2.ZERO
@export var zoom: Vector2 = Vector2.ONE
@export_group("Room")
@export var room: Node2D
@export var auto_detect_bounds: bool = true
@export var room_bounds: Rect2


func _ready() -> void:
	var cam := Camera2D.new()
	cam.name = &"Camera2D"
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.position_smoothing_enabled = false
	cam.zoom = zoom
	add_child(cam)
	cam.make_current()

	if not target:
		_resolve_target()

	_resolve_target_body()

	if auto_detect_bounds:
		detect_bounds_from_room()

	if target:
		global_position = _clamp(target.global_position + follow_offset)


func _process(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	if not enabled:
		return

	global_position = _clamp(target.global_position + follow_offset)


func _clamp(pos: Vector2) -> Vector2:
	if not room_bounds.has_area():
		return pos
	var screen_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	var half_view := screen_size / zoom * 0.5
	pos.x = clampf(pos.x, room_bounds.position.x + half_view.x, room_bounds.end.x - half_view.x)
	pos.y = clampf(pos.y, room_bounds.position.y + half_view.y, room_bounds.end.y - half_view.y)
	return pos


func set_target(new_target: Node2D) -> void:
	target = new_target
	_resolve_target_body()


func set_room_bounds(new_bounds: Rect2) -> void:
	room_bounds = new_bounds


func set_room(room_node: Node2D, refresh_bounds: bool = true) -> void:
	room = room_node
	if refresh_bounds and auto_detect_bounds:
		detect_bounds_from_room()


func detect_bounds_from_room() -> void:
	var room_node := _resolve_room_node()
	if not room_node:
		return
	var combined := Rect2()
	var found := false
	for tile_map in room_node.find_children("*", "TileMapLayer", true, false):
		var tile_bounds := _bounds_from_tile_map_layer(tile_map as TileMapLayer)
		if not tile_bounds.has_area():
			continue
		combined = tile_bounds if not found else combined.merge(tile_bounds)
		found = true
	if found:
		room_bounds = combined


func _resolve_target() -> void:
	if target and is_instance_valid(target):
		return
	if not is_inside_tree():
		return

	var sibling := get_node_or_null(NodePath("../Character"))
	if sibling and sibling is Node2D:
		target = sibling as Node2D
		return

	var parent_node := get_parent()
	if parent_node:
		for child in parent_node.get_children():
			if child is Player or child is CharacterBody2D:
				target = child as Node2D
				return

	var players := get_tree().current_scene.find_children("*", "Player", true, false)
	if not players.is_empty():
		target = players[0] as Node2D


func _resolve_target_body() -> void:
	if not target or not is_instance_valid(target):
		return
	if target is CharacterBody2D:
		return
	var body := target.find_children("*", "CharacterBody2D", false, false)
	if not body.is_empty():
		target = body[0] as Node2D


func _resolve_room_node() -> Node2D:
	if room and is_instance_valid(room):
		return room
	if is_inside_tree():
		return get_parent() as Node2D
	return null


func _bounds_from_tile_map_layer(tile_map: TileMapLayer) -> Rect2:
	var used := tile_map.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Rect2()
	var ts: Vector2i = tile_map.tile_set.tile_size
	var origin: Vector2 = tile_map.global_position
	var start := origin + Vector2(used.position) * Vector2(ts)
	var end := origin + Vector2(used.end) * Vector2(ts)
	return Rect2(start, end - start)
