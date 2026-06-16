class_name InputComponent
extends Node

const INPUT_BUFFER_TIME := 0.15

var command := InputCommand.new()


func _process(delta: float) -> void:
	update_input(delta)


func update_input(delta: float) -> void:

	_update_buffers(delta)

	command.move_direction = Input.get_axis(
		"move_left",
		"move_right"
	)

	command.jump_held = Input.is_action_pressed("jump")
	command.attack_held = Input.is_action_pressed("attack")

	if Input.is_action_just_pressed("jump"):
		command.jump_buffer = INPUT_BUFFER_TIME

	if Input.is_action_just_pressed("attack"):
		command.attack_buffer = INPUT_BUFFER_TIME

	if Input.is_action_just_pressed("dash"):
		command.dash_buffer = INPUT_BUFFER_TIME

	if Input.is_action_just_pressed("interact"):
		command.interact_buffer = INPUT_BUFFER_TIME


func _update_buffers(delta: float) -> void:

	command.jump_buffer = max(
		command.jump_buffer - delta,
		0.0
	)

	command.attack_buffer = max(
		command.attack_buffer - delta,
		0.0
	)

	command.dash_buffer = max(
		command.dash_buffer - delta,
		0.0
	)

	command.interact_buffer = max(
		command.interact_buffer - delta,
		0.0
	)


func get_command() -> InputCommand:
	return command
