class_name EnemyPatrolState
extends EnemyState

@export var patrol_distance: float = 80.0

var _patrol_origin_x: float
var _direction: float = 1.0


func enter() -> void:
	_patrol_origin_x = actor.global_position.x
	_direction = 1.0 if actor.facing_direction.x >= 0.0 else -1.0


func physics_update_state(_delta: float) -> void:
	if not actor.is_on_floor():
		change_state("Fall")
		return

	if actor.is_on_wall():
		_direction *= -1.0
	else:
		var offset := actor.global_position.x - _patrol_origin_x
		if offset >= patrol_distance:
			_direction = -1.0
		elif offset <= -patrol_distance:
			_direction = 1.0

	actor.facing_direction.x = _direction
	actor.move(_direction)
