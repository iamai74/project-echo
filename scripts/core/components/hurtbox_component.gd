class_name HurtboxComponent
extends Area2D

signal hit_received(attack: AttackData)
signal damage_blocked()

var _is_invulnerable := false

func _ready():
	pass

func can_receive_hit() -> bool:
	return not _is_invulnerable

func set_invulnerable(value: bool) -> void:
	_is_invulnerable = value

func receive_hit(attack: AttackData):

	if not can_receive_hit():
		damage_blocked.emit()
		return
	hit_received.emit(attack)
