class_name PlayerJumpAttackState
extends PlayerState


func enter() -> void:
	player.start_air_attack()


func physics_update(_delta: float) -> void:
	if not player.is_attack_finished():
		return

	if is_grounded():
		if has_movement_input():
			change_state("Move")
		else:
			change_state("Idle")
