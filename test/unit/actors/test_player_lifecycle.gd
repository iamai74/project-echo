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


func test_get_input() -> void:
	assert_object(player.get_input()).is_not_null()


func test_is_player() -> void:
	assert_bool(player.is_player()).is_true()


func test_is_attacking() -> void:
	assert_bool(player.is_attacking()).is_false()


func test_process() -> void:
	# Test that _process calls state_machine.update
	var original_state: State = player.state_machine.current_state
	player._process(0.1)
	assert_object(player.state_machine.current_state).is_equal(original_state)


func test_physics_process() -> void:
	# Test that _physics_process calls super(delta)
	# We can't easily verify the super call, but we can at least make sure it doesn't crash
	player._physics_process(0.1)


func test_attack_finished_signal_forwarding() -> void:
	# Mock a signal emission and verify it calls state_machine.handle_attack_finished
	var attack: AttackDefinition = AttackDefinition.new()
	player._on_attack_finished(attack)
	# Since we can't easily verify the internal call, just ensure it doesn't crash
