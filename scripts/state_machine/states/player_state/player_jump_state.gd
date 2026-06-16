class_name PlayerJumpState
extends PlayerState


func enter() -> void:
	player.jump()


func physics_update_state(_delta: float) -> void:

	if player.velocity.y > 0:
		change_state("Fall")
