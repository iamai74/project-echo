class_name BakeStep
extends RefCounted


func get_id() -> StringName:
	return &""


func get_display_name() -> String:
	return ""


func run(context: RoomBakeContext) -> RoomBakeContext:
	return context
