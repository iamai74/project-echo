## WeaponComponent unit tests.
## Covers: attack start and rejection, missing attack definitions, phase progression,
## timer accumulation, hitbox activation/sizing/mirroring, signals and interruption.
extends GdUnitTestSuite


var actor: Actor
var weapon: WeaponComponent
var hitbox: HitboxComponent
var hitbox_shape: CollisionShape2D
var weapon_data: WeaponData
var light_attack: AttackDefinition


func before_test() -> void:
	actor = auto_free(Actor.new()) as Actor
	actor.name = "Actor"
	actor.data = ActorData.new()

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	actor.add_child(hurtbox)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	actor.add_child(state_machine)

	light_attack = AttackDefinition.new()
	light_attack.attack_type = AttackType.Type.LIGHT
	light_attack.damage = 12
	light_attack.knockback_force = 60.0
	light_attack.startup = 0.1
	light_attack.active = 0.2
	light_attack.recovery = 0.3
	light_attack.hitbox_offset = Vector2(20.0, -4.0)
	light_attack.hitbox_size = Vector2(40.0, 24.0)

	weapon_data = WeaponData.new()
	weapon_data.attacks.append(light_attack)

	hitbox_shape = CollisionShape2D.new()
	hitbox_shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8.0, 8.0)
	hitbox_shape.shape = rectangle

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	hitbox.add_child(hitbox_shape)

	weapon = auto_free(WeaponComponent.new()) as WeaponComponent
	weapon.name = "WeaponComponent"
	weapon.weapon_data = weapon_data
	weapon.add_child(hitbox)
	actor.add_child(weapon)

	add_child(actor)

	# Drive phase progression explicitly so frame timing cannot affect the assertions.
	actor.set_physics_process(false)
	weapon.set_physics_process(false)


func _advance_to_active() -> void:
	weapon.start_attack(AttackType.Type.LIGHT)
	weapon._physics_process(light_attack.startup + 0.01)


func _advance_to_recovery() -> void:
	_advance_to_active()
	weapon._physics_process(light_attack.active + 0.01)


func _advance_to_idle() -> void:
	_advance_to_recovery()
	weapon._physics_process(light_attack.recovery + 0.01)


# --- Initialisation ---

func test_ready_initializes_weapon_data() -> void:
	assert_object(weapon_data.get_attack(AttackType.Type.LIGHT)).is_same(light_attack)
	assert_bool(weapon.can_attack()).is_true()
	assert_bool(weapon.is_attacking()).is_false()


# --- Starting an attack ---

func test_start_attack_when_idle_enters_startup() -> void:
	weapon.start_attack(AttackType.Type.LIGHT)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.STARTUP)
	assert_float(weapon._timer).is_equal(light_attack.startup)
	assert_bool(weapon.can_attack()).is_false()
	assert_bool(weapon.is_attacking()).is_true()


func test_start_attack_builds_attack_data_from_definition() -> void:
	actor.facing_direction = Vector2.LEFT

	weapon.start_attack(AttackType.Type.LIGHT)

	assert_object(weapon._current_attack).is_same(light_attack)
	assert_object(weapon._current_attack_data).is_not_null()
	assert_int(weapon._current_attack_data.damage).is_equal(light_attack.damage)
	assert_float(weapon._current_attack_data.knockback_force).is_equal(light_attack.knockback_force)
	assert_object(weapon._current_attack_data.source).is_same(actor)
	assert_vector(weapon._current_attack_data.direction).is_equal(Vector2.LEFT)


func test_start_attack_emits_started_signal() -> void:
	monitor_signals(weapon, false)

	weapon.start_attack(AttackType.Type.LIGHT)

	await assert_signal(weapon).is_emitted("attack_started", light_attack)


func test_start_attack_while_already_attacking_is_rejected() -> void:
	weapon.start_attack(AttackType.Type.LIGHT)
	weapon._timer = 0.25

	weapon.start_attack(AttackType.Type.LIGHT)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.STARTUP)
	assert_float(weapon._timer).is_equal(0.25)
	assert_object(weapon._current_attack).is_same(light_attack)


func test_start_attack_during_active_is_rejected() -> void:
	_advance_to_active()

	weapon.start_attack(AttackType.Type.LIGHT)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.ACTIVE)
	assert_bool(weapon.can_attack()).is_false()


func test_start_attack_with_missing_definition_pushes_error() -> void:
	assert_error(func() -> void: weapon.start_attack(AttackType.Type.HEAVY)) \
		.is_push_error("[WeaponComponent] Attack not found for type: HEAVY")

	assert_bool(weapon.can_attack()).is_true()
	assert_object(weapon._current_attack).is_null()
	assert_object(weapon._current_attack_data).is_null()


# --- Phase progression ---

func test_physics_process_ignores_timer_when_idle() -> void:
	weapon._timer = 99.0

	weapon._physics_process(1.0)

	assert_float(weapon._timer).is_equal(99.0)
	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)


func test_physics_process_accumulates_timer_within_startup() -> void:
	weapon.start_attack(AttackType.Type.LIGHT)

	weapon._physics_process(0.04)
	weapon._physics_process(0.04)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.STARTUP)
	assert_float(weapon._timer).is_equal_approx(light_attack.startup - 0.08, 0.0001)
	assert_bool(weapon.is_attacking()).is_true()


func test_physics_process_early_return_while_active_keeps_hitbox_active() -> void:
	_advance_to_active()

	weapon._physics_process(0.05)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.ACTIVE)
	assert_bool(hitbox.active).is_true()
	assert_bool(hitbox.monitoring).is_true()


func test_phase_progression_reaches_idle_after_recovery() -> void:
	_advance_to_recovery()
	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.RECOVERY)

	weapon._physics_process(light_attack.recovery + 0.01)

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)
	assert_float(weapon._timer).is_zero()
	assert_bool(weapon.can_attack()).is_true()
	assert_bool(weapon.is_attacking()).is_false()


# --- Hitbox behaviour ---

func test_hitbox_activates_only_during_active_phase() -> void:
	weapon.start_attack(AttackType.Type.LIGHT)
	assert_bool(hitbox.active).is_false()
	assert_bool(hitbox.monitoring).is_false()

	weapon._physics_process(light_attack.startup + 0.01)
	assert_bool(hitbox.active).is_true()
	assert_bool(hitbox.monitoring).is_true()

	weapon._physics_process(light_attack.active + 0.01)
	assert_bool(hitbox.active).is_false()
	assert_bool(hitbox.monitoring).is_false()


func test_hitbox_stays_inactive_after_attack_finishes() -> void:
	_advance_to_idle()

	assert_bool(hitbox.active).is_false()
	assert_bool(hitbox.monitoring).is_false()


func test_active_hitbox_offset_faces_right() -> void:
	actor.facing_direction = Vector2.RIGHT

	_advance_to_active()

	assert_vector(hitbox.position).is_equal(light_attack.hitbox_offset)


func test_active_hitbox_offset_is_mirrored_when_facing_left() -> void:
	actor.facing_direction = Vector2.LEFT

	_advance_to_active()

	var expected := Vector2(-light_attack.hitbox_offset.x, light_attack.hitbox_offset.y)
	assert_vector(hitbox.position).is_equal(expected)


func test_active_hitbox_sizes_rectangle_shape() -> void:
	_advance_to_active()

	var rectangle := hitbox_shape.shape as RectangleShape2D
	assert_object(rectangle).is_not_null()
	assert_vector(rectangle.size).is_equal(light_attack.hitbox_size)


func test_active_hitbox_sizes_capsule_shape() -> void:
	var capsule := CapsuleShape2D.new()
	hitbox_shape.shape = capsule

	_advance_to_active()

	assert_object(hitbox_shape.shape).is_not_null()
	assert_bool(hitbox_shape.shape is CapsuleShape2D).is_true()
	assert_float((hitbox_shape.shape as CapsuleShape2D).radius).is_equal(40.0)
	assert_float((hitbox_shape.shape as CapsuleShape2D).mid_height).is_equal(24.0)


# --- Finishing and interrupting ---

func test_attack_finished_signal_is_emitted_after_recovery() -> void:
	monitor_signals(weapon, false)
	_advance_to_recovery()

	weapon._physics_process(light_attack.recovery + 0.01)

	await assert_signal(weapon).is_emitted("attack_finished", light_attack)
	assert_object(weapon._current_attack).is_null()
	assert_object(weapon._current_attack_data).is_null()


func test_interrupt_attack_during_active_clears_state() -> void:
	_advance_to_active()

	weapon.interrupt_attack()

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)
	assert_float(weapon._timer).is_zero()
	assert_object(weapon._current_attack).is_null()
	assert_object(weapon._current_attack_data).is_null()
	assert_bool(hitbox.active).is_false()
	assert_bool(hitbox.monitoring).is_false()


func test_interrupt_attack_when_idle_is_noop() -> void:
	weapon.interrupt_attack()

	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)
	assert_bool(weapon.can_attack()).is_true()
	assert_bool(weapon.is_attacking()).is_false()
