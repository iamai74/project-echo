## PlayerState unit tests.
## Covers: movement threshold, command consumption, grounded/falling helpers,
## global transitions (death, jump, attack, dash) and suppression in combat
## states.
extends GdUnitTestSuite


const Fixture = preload("res://scripts/test/fixtures/actor_state_fixture.gd")


var player


func before_test() -> void:
	player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)


func _state(state_name: String) -> PlayerState:
	return player.state_machine.states[state_name] as PlayerState


func _command() -> InputCommand:
	return player.input_component.get_command()


# ── Movement input ───────────────────────────────────────────────────

func test_has_movement_input_uses_threshold() -> void:
	var state := _state("Idle")

	_command().move_direction = 0.011
	assert_bool(state.has_movement_input()).is_true()

	_command().move_direction = 0.01
	assert_bool(state.has_movement_input()).is_false()

	_command().move_direction = -0.011
	assert_bool(state.has_movement_input()).is_true()


# ── Command consumption ──────────────────────────────────────────────

func test_consume_jump_consumes_exactly_one_command() -> void:
	var state := _state("Idle")
	_command().add_command(Command.new(CommandType.Type.JUMP))
	_command().add_command(Command.new(CommandType.Type.JUMP))

	assert_bool(state.consume_jump()).is_true()
	assert_int(_command().commands.size()).is_equal(1)
	assert_bool(state.consume_jump()).is_true()
	assert_bool(state.consume_jump()).is_false()


func test_consume_attack_consumes_exactly_one_command() -> void:
	var state := _state("Idle")
	_command().add_command(Command.new(CommandType.Type.ATTACK))
	_command().add_command(Command.new(CommandType.Type.ATTACK))

	assert_bool(state.consume_attack()).is_true()
	assert_int(_command().commands.size()).is_equal(1)
	assert_bool(state.consume_attack()).is_true()
	assert_bool(state.consume_attack()).is_false()


func test_consume_dash_consumes_exactly_one_command() -> void:
	var state := _state("Idle")
	_command().add_command(Command.new(CommandType.Type.DASH))

	assert_bool(state.consume_dash()).is_true()
	assert_bool(state.consume_dash()).is_false()


# ── Grounded / falling helpers ───────────────────────────────────────

func test_is_grounded_and_is_falling_reflect_actor_state() -> void:
	var state := _state("Idle")

	player.grounded = true
	assert_bool(state.is_grounded()).is_true()

	player.grounded = false
	assert_bool(state.is_grounded()).is_false()

	player.velocity.y = 0.0
	assert_bool(state.is_falling()).is_false()

	player.velocity.y = 5.0
	assert_bool(state.is_falling()).is_true()


# ── Global transitions ───────────────────────────────────────────────

func test_global_death_transition_wins_over_other_commands() -> void:
	var state := _state("Idle")
	player.health.current_health = 0
	_command().add_command(Command.new(CommandType.Type.JUMP))

	state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Dead")
	assert_bool(player.died).is_true()


func test_global_transitions_are_ignored_in_attack_state() -> void:
	var attack_state := _state("Attack")
	player.state_machine.change_state("Attack")
	_command().add_command(Command.new(CommandType.Type.JUMP))

	attack_state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Attack")
	assert_bool(_command().has_command(CommandType.Type.JUMP)).is_true()


func test_global_transitions_are_ignored_in_hurt_state() -> void:
	var hurt_player = auto_free(Fixture.build_player())
	Fixture.add_state(hurt_player.state_machine, "Idle", PlayerIdleState.new())
	Fixture.add_state(hurt_player.state_machine, "Hurt", PlayerState.new())
	Fixture.start(hurt_player)
	hurt_player.state_machine.change_state("Hurt")

	var hurt_state: PlayerState = hurt_player.state_machine.states["Hurt"]
	hurt_player.input_component.get_command().add_command(Command.new(CommandType.Type.JUMP))

	hurt_state.physics_update(0.0)

	assert_str(hurt_player.state_machine.current_state.name).is_equal("Hurt")


func test_jump_command_decrements_jump_count_when_jumps_remain() -> void:
	var state := _state("Idle")
	player.jump_count = 1
	_command().add_command(Command.new(CommandType.Type.JUMP))

	state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Jump")
	assert_int(player.jump_count).is_zero()


func test_jump_command_is_consumed_but_ignored_when_no_jumps_remain() -> void:
	var state := _state("Idle")
	player.grounded = true
	player.jump_count = 0
	_command().add_command(Command.new(CommandType.Type.JUMP))

	state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Idle")
	# The command is consumed regardless so it cannot be buffered until landing.
	assert_bool(_command().has_command(CommandType.Type.JUMP)).is_false()


func test_attack_command_transitions_to_attack() -> void:
	var state := _state("Idle")
	player.grounded = true
	_command().add_command(Command.new(CommandType.Type.ATTACK))

	state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Attack")


func test_dash_command_transitions_to_dash() -> void:
	var state := _state("Idle")
	player.grounded = true
	_command().add_command(Command.new(CommandType.Type.DASH))

	state.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Dash")
