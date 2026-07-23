class_name EnemyIdleState
extends EnemyState


func physics_update_state(_delta: float) -> void:
	actor.velocity.x = 0
	if not actor.is_on_floor():
		change_state("Fall")
		return
