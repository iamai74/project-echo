class_name ValidateStep
extends BakeStep


func get_id() -> StringName:
	return &"validate"


func get_display_name() -> String:
	return "ValidateStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	var validators: Array[BakeValidator] = [
		DuplicateCellValidator.new(),
		SemanticOverlapValidator.new(),
		TopologyValidator.new(),
		SemanticCellValidator.new()
	]
	for validator in validators:
		validator.validate(context)
	return context
