class_name EmenyHurtState
extends EnemyState

func enter() -> void:
	actor.set_invulnerable(true)
	
func exit() -> void:
	actor.set_invulnerable(false)
	
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
