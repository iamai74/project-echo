@tool
class_name SpatialBrush
extends SemanticBrush

@export var size: Vector2i = Vector2i.ONE


func _draw_preview() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BRUSH_COLOR, false, 2.0)
