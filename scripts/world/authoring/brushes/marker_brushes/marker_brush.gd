@tool
class_name MarkerBrush
extends SemanticBrush

## A one-cell authoring marker that records gameplay intent for a room.
##
## `position` is the top-left grid cell of the marker's cell. The effective
## placement point is the midpoint of that cell's lower edge:
## `cell_origin + Vector2(tile_size.x * 0.5, tile_size.y)`.
## Runtime consumers use this anchor for every marker type.

const FILL_ALPHA := 0.3

@export var marker_type: MarkerType.Value = MarkerType.Value.ENEMY_SPAWN:
	set(value):
		marker_type = value
		queue_redraw()

@export var content_id: StringName:
	set(value):
		content_id = value
		queue_redraw()

@export var marker_id: StringName:
	set(value):
		marker_id = value
		queue_redraw()


func get_brush_type() -> BrushType:
	return BrushType.MARKER


func is_valid_brush() -> bool:
	return super() and size == Vector2i.ONE


func get_fill_color() -> Color:
	var fill := _get_type_color()
	fill.a = FILL_ALPHA
	return fill


func get_outline_color() -> Color:
	return _get_type_color()


func _get_type_color() -> Color:
	match marker_type:
		MarkerType.Value.ENEMY_SPAWN:
			return Color.ORANGE
		MarkerType.Value.LOOT_SPAWN:
			return Color.GOLD
		MarkerType.Value.CHECKPOINT:
			return Color.CYAN
	return Color.WHITE


func get_label() -> String:
	var lines: PackedStringArray = [MarkerType.name_of(marker_type)]
	if content_id == &"":
		lines.append("<missing content_id>")
	else:
		lines.append(String(content_id))
	if marker_id != &"":
		lines.append(String(marker_id))
	return "\n".join(lines)
