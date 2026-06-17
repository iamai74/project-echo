class_name PlayerJumpState
extends PlayerState


func enter() -> void:
	player.jump()


func physics_update_state(_delta: float) -> void:

	var direction := input_component.get_command().move_direction
	player.move(direction)

	if player.velocity.y > 0:
		change_state("Fall")
