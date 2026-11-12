## Enemy unit tests.
## Covers: lifecycle, component wiring, signal forwarding, and scene boot.
extends GdUnitTestSuite

const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")

const EnemyScene = preload("res://test/fixtures/enemy_scene.tscn")

var enemy

func before_test() -> void:
	enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy)


func test_boots_into_idle() -> void:
	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")


func test_enemy_scene_ready_wires_components() -> void:
	# Load the enemy scene and instantiate it
	var enemy_scene = auto_free(EnemyScene.instantiate())

	# Add it to the scene tree so _ready() runs
	add_child(enemy_scene)

	# After adding to tree, _ready() should have run
	# Locate the CharacterBody2D actor
	var enemy = enemy_scene.get_node("CharacterBody2D") as Enemy
	assert_object(enemy).is_not_null()

	# Assert all @onready references are non-null
	assert_object(enemy.health).is_not_null()
	assert_object(enemy.hurtbox).is_not_null()
	assert_object(enemy.state_machine).is_not_null()
	assert_object(enemy.sprite).is_not_null()
	assert_object(enemy.detection_component).is_not_null()

	# Assert health was initialized from ActorData (10, not default 100)
	assert_int(enemy.health.max_health).is_equal(10)
	assert_int(enemy.health.current_health).is_equal(10)

	# Assert initial state is Idle (no physics frame should have run yet)
	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")

	# Assert detection signals are connected
	assert_bool(enemy.detection_component.player_detected.is_connected(enemy._on_player_detected)).is_true()
	assert_bool(enemy.detection_component.player_lost.is_connected(enemy._on_player_lost)).is_true()

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

# A prior test here checked stub setup rather than real signal connections.
# Real scene wiring (detection signals, boot to Idle) is now covered by
# test_enemy_scene_ready_wires_components in this file.
