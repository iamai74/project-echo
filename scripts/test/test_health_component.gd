## HealthComponent unit tests.
## Covers: initial values, damage, healing, clamping, invalid damage/heal, death emitted once,
## health percentage, and max-health changes.
extends GdUnitTestSuite


var health: HealthComponent
var _death_count: int


func before_test() -> void:
	health = auto_free(HealthComponent.new())
	health.current_health = 100
	health.max_health = 100
	_death_count = 0


func _on_health_died() -> void:
	_death_count += 1


func test_initial_values_default() -> void:
	var hc = auto_free(HealthComponent.new())
	assert_int(hc.current_health).is_equal(100)
	assert_int(hc.max_health).is_equal(100)
	assert_bool(hc.is_alive()).is_true()


func test_initialize_sets_health() -> void:
	health.initialize(200)
	assert_int(health.max_health).is_equal(200)
	assert_int(health.current_health).is_equal(200)


func test_take_damage_reduces_health() -> void:
	var data = AttackData.new(25)
	health.take_damage(data)
	assert_int(health.current_health).is_equal(75)


func test_take_damage_emits_damaged_signal() -> void:
	monitor_signals(health, false)
	var data = AttackData.new(30)
	health.take_damage(data)
	await assert_signal(health).is_emitted("damaged", 30)


func test_take_damage_emits_health_changed_signal() -> void:
	monitor_signals(health, false)
	var data = AttackData.new(10)
	health.take_damage(data)
	await assert_signal(health).is_emitted("health_changed", 90, 100)


func test_take_zero_damage_does_nothing() -> void:
	var data = AttackData.new(0)
	health.take_damage(data)
	assert_int(health.current_health).is_equal(100)


func test_take_negative_damage_does_nothing() -> void:
	var data = AttackData.new(-10)
	health.take_damage(data)
	assert_int(health.current_health).is_equal(100)


func test_health_clamps_to_zero() -> void:
	monitor_signals(health, false)
	var data = AttackData.new(200)
	health.take_damage(data)
	assert_int(health.current_health).is_zero()
	assert_bool(health.is_alive()).is_false()


func test_death_emitted_once_on_zero_health() -> void:
	health.died.connect(_on_health_died)
	monitor_signals(health, false)
	var kill_data = AttackData.new(100)
	health.take_damage(kill_data)
	await assert_signal(health).is_emitted("died")
	# further damage should not re-emit died
	var extra_data = AttackData.new(50)
	health.take_damage(extra_data)
	assert_int(_death_count).is_equal(1)


func test_heal_increases_health() -> void:
	health.current_health = 60
	health.heal(20)
	assert_int(health.current_health).is_equal(80)


func test_heal_emits_healed_signal() -> void:
	monitor_signals(health, false)
	health.current_health = 60
	health.heal(25)
	await assert_signal(health).is_emitted("healed", 25)


func test_heal_clamps_to_max_health() -> void:
	health.current_health = 90
	health.heal(50)
	assert_int(health.current_health).is_equal(100)


func test_heal_zero_does_nothing() -> void:
	health.heal(0)
	assert_int(health.current_health).is_equal(100)


func test_heal_negative_does_nothing() -> void:
	health.heal(-10)
	assert_int(health.current_health).is_equal(100)


func test_get_health_percentage_full() -> void:
	assert_float(health.get_health_percentage()).is_equal(1.0)


func test_get_health_percentage_half() -> void:
	health.current_health = 50
	assert_float(health.get_health_percentage()).is_equal(0.5)


func test_get_health_percentage_zero() -> void:
	health.current_health = 0
	assert_float(health.get_health_percentage()).is_zero()


func test_get_health_percentage_max_zero() -> void:
	health.max_health = 0
	health.current_health = 0
	assert_float(health.get_health_percentage()).is_zero()


func test_set_max_health_reduces_current_when_lower() -> void:
	health.current_health = 80
	health.set_max_health(50)
	assert_int(health.max_health).is_equal(50)
	assert_int(health.current_health).is_equal(50)


func test_set_max_health_keeps_current_when_higher() -> void:
	health.current_health = 40
	health.set_max_health(150)
	assert_int(health.max_health).is_equal(150)
	assert_int(health.current_health).is_equal(40)


func test_set_max_health_emits_died_when_drops_to_zero() -> void:
	monitor_signals(health, false)
	health.current_health = 10
	health.set_max_health(5)
	assert_int(health.current_health).is_equal(5)
	assert_bool(health.is_alive()).is_true()
	health.set_max_health(0)
	await assert_signal(health).is_emitted("died")


func test_damage_after_death_does_nothing() -> void:
	var kill_data = AttackData.new(100)
	health.take_damage(kill_data)
	assert_bool(health.is_alive()).is_false()
	# further damage is a no-op
	var extra_data = AttackData.new(10)
	health.take_damage(extra_data)
	assert_int(health.current_health).is_zero()
