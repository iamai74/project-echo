class_name PlayerAttackState
extends PlayerState


func enter() -> void:
	player.lock_input()
	hitbox_component.activate()
	
func exit() -> void:
	hitbox_component.deactivate()
	player.unlock_input()
	
func physics_update(_delta: float) -> void:

	if not player.is_attack_finished():
		return

	if not is_grounded():
		change_state("Fall")
		return

	if has_movement_input():
		change_state("Move")
	else:
		change_state("Idle")
