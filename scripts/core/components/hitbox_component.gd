class_name HitboxComponent
extends Area2D

signal hit_target(target)

@export var damage: int = 10
@export var knockback_force: float = 150.0

var active := false
var hit_targets := {}


func _ready():
	area_entered.connect(_on_area_entered)


func activate():
	active = true
	monitoring = true
	hit_targets.clear()
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

	var attack := AttackData.new(
		damage,
		knockback_force,
		owner,
		owner.global_position.direction_to(
			area.global_position
		)
	)

	area.receive_hit(attack)

	hit_target.emit(area)
