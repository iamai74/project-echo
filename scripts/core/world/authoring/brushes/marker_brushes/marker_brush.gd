@tool
class_name MarkerBrush
extends SemanticBrush

@export var size: Vector2i = Vector2i.ONE


func _draw_preview() -> void:
	var color_with_alpha = Color(BRUSH_COLOR, 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), color_with_alpha, false, 2.0)
