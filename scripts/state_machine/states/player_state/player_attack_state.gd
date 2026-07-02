class_name PlayerAttackState
extends PlayerState


func enter() -> void:
	player.lock_input()
	player.attack(AttackType.Type.LIGHT)


func exit() -> void:
	player.unlock_input()


func on_attack_finished(attack: AttackDefinition) -> void:
	var next_state := "Idle"
	if not is_grounded():
		next_state = "Fall"
	elif has_movement_input():
		next_state = "Move"
	if not is_grounded():
		change_state("Fall")
	elif has_movement_input():
		change_state("Move")
	else:
		change_state("Idle")
