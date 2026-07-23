class_name AttackData
extends RefCounted

var damage: int
var knockback_force: float
var source: Node
var direction: Vector2


func _init(
	damage_value: int,
	knockback_value: float = 0.0,
	attack_source: Node = null,
	attack_direction: Vector2 = Vector2.ZERO
):
	damage = damage_value
	knockback_force = knockback_value
	source = attack_source
	direction = attack_direction
