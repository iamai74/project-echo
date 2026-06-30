class_name PlayerAttackState
extends PlayerState

const ATTACK_DURATION := 0.3

var _attack_timer := 0.0


func enter() -> void:
	_attack_timer = ATTACK_DURATION
	player.lock_input()
	print("Attack state enter")
	hitbox_component.activate()
	
func exit() -> void:
	hitbox_component.deactivate()
	player.unlock_input()
	print("Attack state ended")
	
func physics_update(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return

	if not is_grounded():
		change_state("Fall")
		return

	if has_movement_input():
		change_state("Move")
	else:
		change_state("Idle")
