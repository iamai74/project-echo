class_name ConnectionSide
extends RefCounted

# Append-only: new sides go at the end so serialized integers keep their meaning.
enum Value { TOP, BOTTOM, RIGHT, LEFT }


static func name_of(value: int) -> String:
	var keys: Array = Value.keys()
	if value >= 0 and value < keys.size():
		return String(keys[value])
	return str(value)
