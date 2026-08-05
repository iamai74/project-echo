@tool
class_name SpatialBrush
extends SemanticBrush

@export var size: Vector2i = Vector2i.ONE


func _draw_preview() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), get_brush_color(), false, 2.0)


func get_brush_color() -> Color:
	return Color.WHITE
