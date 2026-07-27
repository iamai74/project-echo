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

const BRUSH_COLOR: Color = Color.WHITE
const BRUSH_NAME: String = "Brush"

@export var enabled: bool = true
@export var priority: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _notification(what: int) -> void:
	if Engine.is_editor_hint() and what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	_draw_preview()


func get_brush_type() -> BrushType:
	push_error("Brush type is not implemented.")
	return BrushType.UNKNOWN


func _draw_preview() -> void:
	pass
