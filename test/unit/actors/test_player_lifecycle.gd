## Player lifecycle and scene wiring tests.
## Covers: component lookup, input lock, and signal forwarding.
extends GdUnitTestSuite

const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")

var player


func before_test() -> void:
	player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)


func test_player_scene_boots_into_idle() -> void:
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

func test_attack_finished_signal_forwarding() -> void:
	var attack: AttackDefinition = AttackDefinition.new()
	var state_machine_spy = spy(player.state_machine)
	player.state_machine = state_machine_spy
	player._on_attack_finished(attack)
	verify(state_machine_spy, 1).handle_attack_finished(attack)
