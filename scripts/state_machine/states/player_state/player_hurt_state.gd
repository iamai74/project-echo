class_name PlayerHurtState
extends PlayerState

func enter() -> void:
	player.lock_input()
	player.set_invulnerable(true)
	
func exit() -> void:
	player.unlock_input()
	player.set_invulnerable(false)

func physics_update(_delta: float) -> void:
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
