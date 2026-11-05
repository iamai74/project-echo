class_name EnemyMoveState
extends EnemyState


func physics_update_state(_delta: float) -> void:
	if not actor.is_grounded():
		change_state("Fall")
		return
