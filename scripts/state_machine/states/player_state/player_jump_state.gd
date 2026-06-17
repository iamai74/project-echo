class_name PlayerJumpState
extends PlayerState


func enter() -> void:
	player.jump()


func physics_update_state(delta: float) -> void:

	var direction := input_component.get_command().move_direction
	player.move(direction)

	if player.velocity.y < 0.0 and input_component.get_command().jump_held:
		player.velocity.y -= player.data.gravity * delta * player.data.jump_hold_force

	if player.velocity.y > 0:
		change_state("Fall")
