class_name WeaponComponent
extends Node

signal attack_started(attack: AttackDefinition)
signal attack_finished(attack: AttackDefinition)

enum AttackPhase {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

@export var weapon_data: WeaponData

@onready var actor: Actor = get_parent() as Actor
@onready var hitbox: HitboxComponent = $HitboxComponent

var _phase: AttackPhase = AttackPhase.IDLE
var _timer: float = 0.0

var _current_attack: AttackDefinition
var _current_attack_data: AttackData

func _ready() -> void:
	weapon_data.initialize()

func _physics_process(delta: float) -> void:
	if _phase == AttackPhase.IDLE:
		return

	_timer -= delta
	if _timer > 0.0:
		return

	match _phase:
		AttackPhase.STARTUP:
			_enter_active()

		AttackPhase.ACTIVE:
			_enter_recovery()

		AttackPhase.RECOVERY:
			_finish_attack()


func can_attack() -> bool:
	var result := _phase == AttackPhase.IDLE
	return result


func is_attacking() -> bool:
	var result := _phase != AttackPhase.IDLE
	return result


func start_attack(type: AttackType.Type) -> void:
	if not can_attack():
		return
	_current_attack = weapon_data.get_attack(type)
	if _current_attack == null:
		push_error("[WeaponComponent] Attack not found for type: ", AttackType.Type.keys()[type])
		return

	_current_attack_data = AttackData.new(
		_current_attack.damage,
		_current_attack.knockback_force,
		actor,
		actor.facing_direction
	)

	_phase = AttackPhase.STARTUP
	_timer = _current_attack.startup

	attack_started.emit(_current_attack)

func interrupt_attack() -> void:
	if not is_attacking():
		return

	hitbox.deactivate()

	_phase = AttackPhase.IDLE
	_timer = 0.0

	_current_attack = null
	_current_attack_data = null


func _enter_active() -> void:
	_phase = AttackPhase.ACTIVE
	_timer = _current_attack.active

	hitbox.activate(_current_attack_data)


func _enter_recovery() -> void:
	hitbox.deactivate()

	_phase = AttackPhase.RECOVERY
	_timer = _current_attack.recovery


func _finish_attack() -> void:
	hitbox.deactivate()

	_phase = AttackPhase.IDLE
	_timer = 0.0

	attack_finished.emit(_current_attack)

	_current_attack = null
	_current_attack_data = null
