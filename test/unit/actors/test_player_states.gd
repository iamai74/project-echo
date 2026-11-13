## Player state behaviour tests.
## Covers: Idle/Move/Fall transitions, Jump physics, Attack lifecycle,
## Hurt lifecycle and JumpAttack state logic.
extends GdUnitTestSuite


const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")


var player


func before_test() -> void:
	player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)


func _state(state_name: String) -> PlayerState:
	return player.state_machine.states[state_name] as PlayerState


func _command() -> InputCommand:
	return player.input_component.get_command()


# ── Idle ─────────────────────────────────────────────────────────────

func test_idle_transitions_to_fall_when_airborne() -> void:
	var idle := _state("Idle")
	player.grounded = false

	idle.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Fall")


func test_idle_transitions_to_move_when_movement_input_present() -> void:
	var idle := _state("Idle")
	player.grounded = true
	_command().move_direction = 0.5

	idle.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Move")


# ── Move ─────────────────────────────────────────────────────────────

func test_move_transitions_to_idle_when_input_stops() -> void:
	player.grounded = true
	player.state_machine.change_state("Move")
	var move := _state("Move")
	_command().move_direction = 0.0

	move.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Idle")


func test_move_transitions_to_fall_when_airborne() -> void:
	player.grounded = false
	player.state_machine.change_state("Move")
	var move := _state("Move")

	move.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Fall")


# ── Jump ─────────────────────────────────────────────────────────────

func test_jump_applies_jump_velocity() -> void:
	player.grounded = true
	player.state_machine.change_state("Jump")

	assert_float(player.velocity.y).is_equal(player.data.jump_velocity)


func test_jump_hold_force_extends_the_jump() -> void:
	player.grounded = true
	player.state_machine.change_state("Jump")
	var jump := _state("Jump")
	var input := player.input_component as Fixture.StubInputComponent
	input.held_actions["jump"] = true

	var initial_velocity: float = player.velocity.y
	jump.physics_update_state(0.1)

	var expected: float = (
		initial_velocity - player.data.gravity * 0.1 * player.data.jump_hold_force
	)
	assert_float(player.velocity.y).is_equal_approx(expected, 0.0001)


func test_jump_transitions_to_fall_after_apex() -> void:
	player.grounded = false
	player.state_machine.change_state("Jump")
	var jump := _state("Jump")
	player.velocity.y = 10.0

	jump.physics_update_state(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Fall")


# ── Fall ─────────────────────────────────────────────────────────────

func test_fall_transitions_to_idle_on_landing() -> void:
	player.grounded = true
	player.state_machine.change_state("Fall")
	var fall := _state("Fall")

	fall.physics_update_state(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Idle")


func test_fall_applies_move_direction_while_airborne() -> void:
	player.grounded = false
	_command().move_direction = 0.5
	player.state_machine.change_state("Fall")
	var fall := _state("Fall")

	fall.physics_update_state(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Fall")
	assert_float(player.velocity.x).is_equal(0.5 * player.data.move_speed)


# ── Attack ───────────────────────────────────────────────────────────

func test_attack_locks_input_and_starts_light_attack() -> void:
	player.grounded = true
	player.state_machine.change_state("Attack")
	var weapon := player.weapon_component as Fixture.StubWeaponComponent

	assert_int(player.input_component.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_array(weapon.started_attacks).contains_exactly([AttackType.Type.LIGHT])


func test_attack_exit_unlocks_input() -> void:
	player.grounded = true
	player.state_machine.change_state("Attack")

	player.state_machine.change_state("Idle")

	assert_int(player.input_component.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)


func test_attack_finishes_into_idle_when_grounded_and_still() -> void:
	player.grounded = true
	player.state_machine.change_state("Attack")
	_command().move_direction = 0.0

	player.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(player.state_machine.current_state.name).is_equal("Idle")


func test_attack_finishes_into_move_when_grounded_and_moving() -> void:
	player.grounded = true
	player.state_machine.change_state("Attack")
	_command().move_direction = 0.5

	player.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(player.state_machine.current_state.name).is_equal("Move")


func test_attack_finishes_into_fall_when_airborne() -> void:
	player.grounded = false
	player.state_machine.change_state("Attack")

	player.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(player.state_machine.current_state.name).is_equal("Fall")


# ── Hurt ─────────────────────────────────────────────────────────────

func test_hurt_exits_to_expected_state(
	grounded: bool,
	move_direction: float,
	dead: bool,
	expected_state: String,
	_test_parameters := [
		[true, 0.5, false, "Move"],
		[true, 0.0, false, "Idle"],
		[false, 0.0, false, "Fall"],
		[true, 0.0, true, "Dead"],
	]) -> void:
	player.state_machine.change_state("Hurt")
	var hurt := _state("Hurt")

	assert_int(player.input_component.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_bool(player.hurtbox.can_receive_hit()).is_false()

	player.grounded = grounded
	_command().move_direction = move_direction
	if dead:
		player.health.current_health = 0

	hurt.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal(expected_state)
	assert_int(player.input_component.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(player.hurtbox.can_receive_hit()).is_true()
	assert_bool(player.died).is_equal(dead)


# ── Dead ─────────────────────────────────────────────────────────────

func test_dead_calls_die_on_entry() -> void:
	player.state_machine.change_state("Dead")

	assert_bool(player.died).is_true()


# ── Jump attack ──────────────────────────────────────────────────────

func test_jump_attack_starts_air_attack_and_waits_for_ground() -> void:
	player.state_machine.change_state("JumpAttack")
	var jump_attack := _state("JumpAttack")

	assert_bool(player.air_attack_started).is_true().is_true()

	player.attack_finished = false
	player.grounded = false
	jump_attack.physics_update(0.0)
	assert_str(player.state_machine.current_state.name).is_equal("JumpAttack")

	player.attack_finished = true
	player.grounded = false
	jump_attack.physics_update(0.0)
	assert_str(player.state_machine.current_state.name).is_equal("JumpAttack")

	player.grounded = true
	_command().move_direction = 0.0
	jump_attack.physics_update(0.0)
	assert_str(player.state_machine.current_state.name).is_equal("Idle")
