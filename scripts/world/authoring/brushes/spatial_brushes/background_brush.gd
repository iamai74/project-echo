@tool
class_name BackgroundBrush
extends SpatialBrush


func get_brush_type() -> BrushType:
	return BrushType.BACKGROUND


func get_fill_color() -> Color:
	return Color.GRAY
