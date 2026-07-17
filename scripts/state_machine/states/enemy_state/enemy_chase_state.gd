class_name EnemyChaseState
extends EnemyState

func physics_update_state(_delta: float) -> void:
	if not actor.is_on_floor():
		change_state("Fall")
		return

	var target_pos = enemy.get_target_position()
	if target_pos != Vector2.INF:
		if actor.distance_to(enemy) <= _get_attack_range():
			change_state("Attack")
			return
		var direction = 1.0 if target_pos.x > actor.global_position.x else -1.0
		actor.facing_direction.x = direction
		actor.move(direction)
	else:
		change_state("Patrol")

func _get_attack_range(attack_type: AttackType.Type = AttackType.Type.LIGHT) -> float:
	var weapon := enemy.weapon_component
	if not weapon or not weapon.weapon_data:
		return 60.0
	var attack := weapon.weapon_data.get_attack(attack_type)
	if not attack:
		return 60.0
	return abs(attack.hitbox_offset.x) + attack.hitbox_size.x * 0.5
