class_name InputComponent
extends Node

const INPUT_BUFFER_TIME := 0.15

const BUFFER_PROPERTIES: Array[StringName] = [
	&"jump_buffer",
	&"attack_buffer",
	&"dash_buffer",
	&"interact_buffer",
]

const BUFFER_ACTIONS: Array[StringName] = [
	&"jump",
	&"attack",
	&"dash",
	&"interact",
]

var command := InputCommand.new()

@export var stick_deadzone: float = 0.2


func _process(delta: float) -> void:
	update_input(delta)


func update_input(delta: float) -> void:
	_tick_buffers(delta)

	command.move_direction = _read_move_axis()
	command.jump_held = Input.is_action_pressed("jump")
	command.attack_held = Input.is_action_pressed("attack")

	for i in BUFFER_PROPERTIES.size():
		if Input.is_action_just_pressed(BUFFER_ACTIONS[i]):
			command.set(BUFFER_PROPERTIES[i], INPUT_BUFFER_TIME)


func get_command() -> InputCommand:
	return command


func _read_move_axis() -> float:
	return _apply_deadzone(Input.get_axis("move_left", "move_right"))


func _apply_deadzone(value: float) -> float:
	var abs_value := absf(value)
	if abs_value < stick_deadzone:
		return 0.0
	return sign(value) * ((abs_value - stick_deadzone) / (1.0 - stick_deadzone))


func _tick_buffers(delta: float) -> void:
	for property in BUFFER_PROPERTIES:
		var value: float = command.get(property)
		command.set(property, maxf(value - delta, 0.0))
