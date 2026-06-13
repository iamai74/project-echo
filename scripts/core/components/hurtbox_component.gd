class_name HurtboxComponent
extends Area2D

signal hit_received(attack: AttackData)
signal damage_blocked()
signal knockback_requested(force: Vector2)

@export var health_component: HealthComponent

var invulnerable := false

func receive_hit(attack: AttackData):

	if invulnerable:
		damage_blocked.emit()
		return

	hit_received.emit(attack)

	health_component.take_damage(attack.damage)

	if attack.knockback_force > 0:
		knockback_requested.emit(attack.direction * attack.knockback_force)
