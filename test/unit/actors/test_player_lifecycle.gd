## Player lifecycle and scene wiring tests.
## Covers: component lookup, input lock, signal forwarding, and scene boot.
extends GdUnitTestSuite

const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")

const PlayerScene = preload("res://test/fixtures/player_scene.tscn")

var player


func before_test() -> void:
	player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)


func test_fixture_boots_into_idle() -> void:
	assert_str(player.state_machine.current_state.name).is_equal("Idle")


func test_component_lookup_succeeds() -> void:
	assert_object(player.get_input()).is_not_null()
	assert_object(player.weapon_component).is_not_null()


func test_input_lock_unlock_changes_processing() -> void:
	player.lock_input()
	assert_bool(player.input_component.is_input_enabled()).is_false()

	player.unlock_input()
	assert_bool(player.input_component.is_input_enabled()).is_true()


func test_is_player() -> void:
	assert_bool(player.is_player()).is_true()


func test_is_attacking() -> void:
	assert_bool(player.is_attacking()).is_false()


func test_process() -> void:
	var state_machine_spy = spy(player.state_machine)
	player.state_machine = state_machine_spy
	player._process(0.1)
	verify(state_machine_spy, 1).update(0.1)

func test_physics_process() -> void:
	var state_machine_spy = spy(player.state_machine)
	player.state_machine = state_machine_spy
	var velocity_before = player.velocity
	player._physics_process(0.1)
	verify(state_machine_spy, 1).physics_update(0.1)
	assert_float(player.velocity.y).is_equal(velocity_before.y + (player.data.gravity * 0.1))


func test_player_scene_ready_wires_components() -> void:
	# Load the player scene and instantiate it
	var player_scene = auto_free(PlayerScene.instantiate())

	# Add it to the scene tree so _ready() runs
	add_child(player_scene)

	# After adding to tree, _ready() should have run and wired everything
	# Locate the CharacterBody2D actor (child of Node2D root)
	var actor = player_scene.get_node("CharacterBody2D") as Player
	assert_object(actor).is_not_null()

	# Assert all @onready references are non-null
	assert_object(actor.health).is_not_null()
	assert_object(actor.hurtbox).is_not_null()
	assert_object(actor.state_machine).is_not_null()
	assert_object(actor.sprite).is_not_null()
	assert_object(actor.weapon_component).is_not_null()
	assert_object(actor.input_component).is_not_null()

	# Assert health was initialized from ActorData (10, not default 100)
	assert_int(actor.health.max_health).is_equal(10)
	assert_int(actor.health.current_health).is_equal(10)

	# Assert initial state is Idle (no physics frame should have run yet)
	assert_str(actor.state_machine.current_state.name).is_equal("Idle")

	# Assert weapon_component.attack_finished is connected to _on_attack_finished
	assert_bool(actor.weapon_component.attack_finished.is_connected(actor._on_attack_finished)).is_true()


func test_attack_finished_signal_forwarding() -> void:
	var attack: AttackDefinition = AttackDefinition.new()
	var state_machine_spy = spy(player.state_machine)
	player.state_machine = state_machine_spy
	player._on_attack_finished(attack)
	verify(state_machine_spy, 1).handle_attack_finished(attack)
