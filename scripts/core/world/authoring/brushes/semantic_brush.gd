@tool
class_name SemanticBrush
extends Node2D

enum BrushType {
	UNKNOWN,
	#spatial
	FLOOR,
	WALL,
	BACKGROUND,
	#marker
	ENEMY_SPAWN,
	LOOT_SPAWN,
	#volume
}

@export var enabled := true:
	set(value):
		enabled = value
		queue_redraw()

@export var size: Vector2i = Vector2i.ONE:
	set(value):
		size = Vector2i(max(1, value.x), max(1, value.y))
		queue_redraw()
@export var priority: int = 0

var selected := false:
	set(value):
		selected = value
		queue_redraw()


func get_brush_type() -> BrushType:
	push_error("Brush type is not implemented.")
	return BrushType.UNKNOWN


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	var rect := _get_rect()
	_draw_fill(rect)
	_draw_grid(rect)
	_draw_outline(rect)
	_draw_label(rect)


func _get_rect() -> Rect2:
	var tile_size := World.settings.tile_size
	return Rect2(Vector2.ZERO, Vector2(size * tile_size))


func _draw_fill(rect: Rect2) -> void:
	var color := get_fill_color()
	if color.a <= 0.0:
		return
	draw_rect(rect, color, true)


func _draw_grid(rect: Rect2) -> void:
	var tile_size := World.settings.tile_size
	var color := get_grid_color()
	for x in range(size.x + 1):
		var px := x * tile_size
		draw_line(Vector2(px, 0), Vector2(px, rect.size.y), color, 1.0)
	for y in range(size.y + 1):
		var py := y * tile_size
		draw_line(Vector2(0, py), Vector2(rect.size.x, py), color, 1.0)


func _draw_outline(rect: Rect2) -> void:
	var color := _resolve_outline_color()
	draw_rect(rect, color, false, get_outline_width())


func _draw_label(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text := get_label()
	var font_size := 14
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := rect.get_center() - text_size * 0.5
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, get_label_color())


func is_valid_brush() -> bool:
	var tile_size := World.settings.tile_size
	return int(position.x) % tile_size == 0 and int(position.y) % tile_size == 0


func _resolve_outline_color() -> Color:
	if not enabled:
		return get_disabled_color()
	if not is_valid_brush():
		return get_invalid_color()
	if selected:
		return get_selected_color()
	return get_outline_color()


func get_label() -> String:
	return "%dx%d" % [size.x, size.y]


func get_fill_color() -> Color:
	return Color.TRANSPARENT


func get_grid_color() -> Color:
	return get_outline_color()


func get_outline_color() -> Color:
	return Color.WHITE


func get_label_color() -> Color:
	return Color.WHITE


func get_disabled_color() -> Color:
	return Color.DIM_GRAY


func get_invalid_color() -> Color:
	return Color.RED


func get_selected_color() -> Color:
	return Color.WHITE


func get_outline_width() -> float:
	return selected if 3.0 else 2.0
