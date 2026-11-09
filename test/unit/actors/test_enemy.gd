## Enemy unit tests.
## Covers: lifecycle, component wiring, and signal forwarding.
extends GdUnitTestSuite

const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")

var enemy

func before_test() -> void:
	enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy)

func test_boots_into_idle() -> void:
	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")

func test_get_target_position_delegates_to_detection() -> void:
	var det = mock(DetectionComponent)
	do_return(Vector2(50, 50)).on(det).get_target_position()
	var real_enemy = auto_free(Enemy.new())
	real_enemy.detection_component = det
	var target_pos = real_enemy.get_target_position()
	assert_vector(target_pos).is_equal(Vector2(50, 50))
	verify(det, 1).get_target_position()

func test_is_attacking_delegates_to_weapon() -> void:
	var weapon_mock = mock(WeaponComponent)
	do_return(true).on(weapon_mock).is_attacking()
	enemy.weapon_component = weapon_mock
	assert_bool(enemy.is_attacking()).is_true()
	verify(weapon_mock, 1).is_attacking()

func test_on_attack_finished_forwards_to_state_machine() -> void:
	var attack = AttackDefinition.new()
	var state_machine_spy = spy(enemy.state_machine)
	enemy.state_machine = state_machine_spy
	enemy._on_attack_finished(attack)
	verify(state_machine_spy, 1).handle_attack_finished(attack)

# This test was removed because it tests stub setup rather than real signal connections.
# Real scene wiring is covered in Step 3.
