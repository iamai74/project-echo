class_name HitboxComponent
extends Area2D

signal hit_target(target)

@export var damage: int = 5
@export var knockback_force: float = 150.0

var active := false
var hit_targets := {}
var _attackData: AttackData

func _ready():
	monitoring = false
	area_entered.connect(_on_area_entered)


func activate(attackData: AttackData):
	active = true
	monitoring = true
	hit_targets.clear()
	_attackData = attackData
	for area in get_overlapping_areas():
		_try_hit(area)

func deactivate():
	active = false
	monitoring = false

func _on_area_entered(area: Area2D):
	_try_hit(area)

func _try_hit(area: Area2D) -> void:
	if not active:
		return

	if not area is HurtboxComponent:
		return

	if area.get_parent() == get_parent():
		return
		
	if hit_targets.has(area):
		return
		
	hit_targets[area] = true
	area.receive_hit(_attackData)
	hit_target.emit(area)
