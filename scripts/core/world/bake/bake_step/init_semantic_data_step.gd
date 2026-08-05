class_name InitSemanticDataStep
extends BakeStep


func get_id() -> StringName:
	return &"init_semantic_data"


func get_display_name() -> String:
	return "InitSemanticDataStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	context.semantic_data = SemanticRoomData.new()
	return context
