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


func test_take_damage_updates_health(initial_health: int, damage: int, expected_health: int, _test_parameters := [
	[100, 25, 75],
	[100, 0, 100],
	[100, -10, 100]
]) -> void:
	health.current_health = initial_health
	var data = AttackData.new(damage)
	health.take_damage(data)
	assert_int(health.current_health).is_equal(expected_health)


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


func test_heal_updates_health(initial_health: int, heal_amount: int, expected_health: int, _test_parameters := [
	[60, 20, 80],
	[60, 0, 60],
	[60, -10, 60],
	[90, 50, 100]
]) -> void:
	health.current_health = initial_health
	health.heal(heal_amount)
	assert_int(health.current_health).is_equal(expected_health)


func test_heal_emits_healed_signal() -> void:
	monitor_signals(health, false)
	health.current_health = 60
	health.heal(25)
	await assert_signal(health).is_emitted("healed", 25)


func test_heal_clamps_to_max_health() -> void:
	health.current_health = 90
	health.heal(50)
	assert_int(health.current_health).is_equal(100)


func test_get_health_percentage_logic(current_health: int, max_health: int, expected_percentage: float, _test_parameters := [
	[100, 100, 1.0],
	[50, 100, 0.5],
	[0, 100, 0.0],
	[0, 0, 0.0]
]) -> void:
	health.current_health = current_health
	health.max_health = max_health
	assert_float(health.get_health_percentage()).is_equal(expected_percentage)


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
