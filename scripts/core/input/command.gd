class_name Command
extends RefCounted

var type: CommandType.Type
var direction: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}


func _init(
	p_type: CommandType.Type, p_direction: Vector2 = Vector2.ZERO, p_metadata: Dictionary = {}
):
	type = p_type
	direction = p_direction
	metadata = p_metadata
