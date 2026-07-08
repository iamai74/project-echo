class_name EnemyChaseState
extends EnemyState

func physics_update_state(_delta: float) -> void:
	if not actor.is_on_floor():
		change_state("Fall")
		return

	if enemy.target_player:
		var player = enemy.target_player
		var direction = 1.0 if player.global_position.x > actor.global_position.x else -1.0
		actor.facing_direction.x = direction
		actor.move(direction)
	else:
		change_state("Patrol")
