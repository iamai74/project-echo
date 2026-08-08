@tool
class_name WallBrush
extends SpatialBrush


func get_brush_type() -> BrushType:
	return BrushType.WALL


func get_fill_color() -> Color:
	return Color.DARK_GREEN
