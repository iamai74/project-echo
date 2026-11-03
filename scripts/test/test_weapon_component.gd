## WeaponComponent unit tests.
## Covers: can_attack when idle, is_attacking state, interrupt resets phase,
## phase transitions (manual), signals.
extends GdUnitTestSuite


var weapon: WeaponComponent


func before_test() -> void:
	weapon = auto_free(WeaponComponent.new())
	# Provide the hitbox nodes normally wired by the weapon scene.
	weapon.hitbox = auto_free(HitboxComponent.new())
	weapon.hitbox_shape = auto_free(CollisionShape2D.new())
	# Ensure idle state
	weapon._phase = WeaponComponent.AttackPhase.IDLE
	weapon._timer = 0.0


# --- Idle state ---

func test_can_attack_when_idle() -> void:
	assert_bool(weapon.can_attack()).is_true()


func test_is_attacking_false_when_idle() -> void:
	assert_bool(weapon.is_attacking()).is_false()


# --- Attacking state ---

func test_cannot_attack_during_startup() -> void:
	weapon._phase = WeaponComponent.AttackPhase.STARTUP
	assert_bool(weapon.can_attack()).is_false()
	assert_bool(weapon.is_attacking()).is_true()


func test_cannot_attack_during_active() -> void:
	weapon._phase = WeaponComponent.AttackPhase.ACTIVE
	assert_bool(weapon.can_attack()).is_false()
	assert_bool(weapon.is_attacking()).is_true()


func test_cannot_attack_during_recovery() -> void:
	weapon._phase = WeaponComponent.AttackPhase.RECOVERY
	assert_bool(weapon.can_attack()).is_false()
	assert_bool(weapon.is_attacking()).is_true()


# --- Interrupt ---

func test_interrupt_resets_to_idle() -> void:
	weapon._phase = WeaponComponent.AttackPhase.STARTUP
	weapon.interrupt_attack()
	assert_bool(weapon.can_attack()).is_true()
	assert_bool(weapon.is_attacking()).is_false()


func test_interrupt_during_active_resets() -> void:
	weapon._phase = WeaponComponent.AttackPhase.ACTIVE
	weapon.interrupt_attack()
	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)


func test_interrupt_during_recovery_resets() -> void:
	weapon._phase = WeaponComponent.AttackPhase.RECOVERY
	weapon.interrupt_attack()
	assert_int(weapon._phase).is_equal(WeaponComponent.AttackPhase.IDLE)


func test_interrupt_when_idle_is_noop() -> void:
	# Interrupt when already idle should not change anything
	weapon.interrupt_attack()
	assert_bool(weapon.can_attack()).is_true()


func test_interrupt_clears_timer() -> void:
	weapon._phase = WeaponComponent.AttackPhase.STARTUP
	weapon._timer = 0.5
	weapon.interrupt_attack()
	assert_float(weapon._timer).is_equal(0.0)
