class_name ValidateStep
extends BakeStep

var _validators: Array[BakeValidator]


func get_id() -> StringName:
	return &"validate"


func get_display_name() -> String:
	return "ValidateStep"


func _init(validators: Array[BakeValidator] = []):
	if validators.is_empty():
		_validators = [
			DuplicateCellValidator.new(),
			SemanticOverlapValidator.new(),
			TopologyValidator.new(),
			SemanticCellValidator.new()
		]
	else:
		_validators = validators



func get_validators() -> Array[BakeValidator]:
	return _validators

func run(context: RoomBakeContext) -> RoomBakeContext:
	for validator in _validators:
		validator.validate(context)
	return context
