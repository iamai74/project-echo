class_name EnemyFallState
extends EnemyState


func physics_update_state(_delta: float) -> void:
	if actor.is_on_floor():
		change_state("Idle")
		return
