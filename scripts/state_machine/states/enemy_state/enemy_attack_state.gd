class_name EnemyAttackState
extends EnemyState


func enter() -> void:
	actor.attack(AttackType.Type.LIGHT)


func exit() -> void:
	pass


func on_attack_finished(attack: AttackDefinition) -> void:
	if not is_grounded():
		change_state("Fall")
	elif has_movement_input():
		change_state("Move")
	else:
		change_state("Idle")
