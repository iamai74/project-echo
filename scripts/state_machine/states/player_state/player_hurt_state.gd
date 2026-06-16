class_name PlayerHurtState
extends PlayerState


func enter() -> void:
	player.apply_hurt_knockback()


func physics_update(_delta: float) -> void:

	if player.is_hurt_finished():

		if is_dead():
			change_state("Dead")
			return

		if is_grounded():

			if has_movement_input():
				change_state("Move")
			else:
				change_state("Idle")
		else:
			change_state("Fall")
