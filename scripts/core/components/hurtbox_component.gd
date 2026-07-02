class_name HurtboxComponent
extends Area2D

signal hit_received(attack: AttackData)
signal damage_blocked()

var invulnerable := false

func _ready():
	pass

func receive_hit(attack: AttackData):

	if invulnerable:
		damage_blocked.emit()
		return
	hit_received.emit(attack)
