@tool
class_name PlatformBrush
extends SpatialBrush

enum Trait {
	ONE_WAY = 1,
	BREAKABLE = 2,
}

@export_flags("One Way:1", "Breakable:2") var traits: int = 0


func get_brush_type() -> BrushType:
	return BrushType.FLOOR


func get_fill_color() -> Color:
	return Color.BLUE


func has_trait(flag: int) -> bool:
	assert(flag != 0)
	assert((flag & (flag - 1)) == 0)
	assert(_is_valid_trait(flag))
	return (traits & flag) != 0


func _is_valid_trait(flag: int) -> bool:
	return Trait.values().has(flag)


func get_label() -> String:
	var label := super()
	if has_trait(Trait.ONE_WAY):
		label += "\nOne Way"
	if has_trait(Trait.BREAKABLE):
		label += "\nBreakable"
	return label
