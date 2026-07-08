class_name HitboxComponent
extends Area2D

signal hit_target(target)

var active := false
var hit_targets := {}
var _attackData: AttackData
var _actor: Actor

func _ready():
	monitoring = false
	area_entered.connect(_on_area_entered)
	_actor = _find_actor(self)


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

func _find_actor(node: Node) -> Actor:
	var parent = node.get_parent()
	while parent:
		if parent is Actor:
			return parent
		parent = parent.get_parent()
	return null

func _on_area_entered(area: Area2D):
	_try_hit(area)

func _try_hit(area: Area2D) -> void:
	if not active:
		return

	if not area is HurtboxComponent:
		return

	if _find_actor(area) == _actor:
		return
		
	if hit_targets.has(area):
		return
		
	hit_targets[area] = true
	area.receive_hit(_attackData)
	hit_target.emit(area)
