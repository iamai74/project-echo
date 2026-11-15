@tool
class_name ConnectionPointBrush
extends SemanticBrush


@export var side: ConnectionSide.Value = ConnectionSide.Value.TOP:
	set(value):
		side = value
		queue_redraw()

@export var connection_id: StringName:
	set(value):
		connection_id = value
		queue_redraw()


func get_brush_type() -> BrushType:
	return BrushType.CONNECTION_POINT


func is_valid_brush() -> bool:
	return super() and _is_orientation_valid()


func _is_orientation_valid() -> bool:
	match side:
		ConnectionSide.Value.TOP, ConnectionSide.Value.BOTTOM:
			return size.y == 1
		ConnectionSide.Value.LEFT, ConnectionSide.Value.RIGHT:
			return size.x == 1
	return false


func get_fill_color() -> Color:
	var fill := Color.CYAN
	fill.a = 0.3
	return fill


func get_outline_color() -> Color:
	return Color.CYAN


func get_label() -> String:
	var lines: PackedStringArray = [_side_name()]
	if connection_id == &"":
		lines.append("<missing connection_id>")
	else:
		lines.append(String(connection_id))
	lines.append("%dx%d" % [size.x, size.y])
	return "\n".join(lines)


func _side_name() -> String:
	var keys: Array = ConnectionSide.Value.keys()
	if side >= 0 and side < keys.size():
		return String(keys[side])
	return "UNKNOWN"
