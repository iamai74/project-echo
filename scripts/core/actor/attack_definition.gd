class_name AttackDefinition
extends Resource

@export_group("Damage")
@export var damage: int = 10
@export var knockback_force: float = 150.0
@export var attack_type: AttackType.Type

@export_group("Timing")
@export var startup: float = 0.08
@export var active: float = 0.10
@export var recovery: float = 0.12

@export_group("Animation")
@export var animation_name: StringName

@export_group("Hitbox")
@export var hitbox_offset: Vector2
@export var hitbox_size: Vector2 = Vector2(32, 24)
