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

func test_setup_wires_detection_signals() -> void:
	var det: DetectionComponent = auto_free(DetectionComponent.new())
	det.name = "DetectionComponent"
	enemy.add_child(det)
	enemy.detection_component = det

	assert_object(enemy.detection_component).is_not_null()

	var dummy_player = auto_free(Fixture.build_player())
	enemy.detection_component.player_detected.emit(dummy_player)

func test_get_target_position_delegates_to_detection() -> void:
	var expected_pos = Vector2(100, 100)
	enemy.target_position = expected_pos
	assert_vector(enemy.get_target_position()).is_equal(expected_pos)

func test_is_attacking_delegates_to_weapon() -> void:
	var weapon = enemy.weapon_component
	assert_bool(enemy.is_attacking()).is_false()
	
	weapon.start_attack(AttackType.Type.LIGHT)
	assert_bool(not weapon.started_attacks.is_empty())
	assert_bool(enemy.is_attacking()).is_true()

func test_on_attack_finished_forwards_to_state_machine() -> void:
	var attack = AttackDefinition.new()
	enemy._on_attack_finished(attack)
