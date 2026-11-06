## Enemy state behaviour tests.
## Covers: locomotion transitions, patrol limits and walls, chase behaviour,
## attack completion, hurt lifecycle and death.
extends GdUnitTestSuite


const Fixture = preload("res://scripts/test/fixtures/actor_state_fixture.gd")


var enemy


func before_test() -> void:
	enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy)


func _state(state_name: String) -> EnemyState:
	return enemy.state_machine.states[state_name] as EnemyState


# ── Locomotion ───────────────────────────────────────────────────────

func test_idle_stops_horizontal_movement_and_falls_when_airborne() -> void:
	enemy.velocity.x = 100.0
	enemy.grounded = false
	var idle := _state("Idle")

	idle.physics_update_state(0.0)

	assert_float(enemy.velocity.x).is_zero()
	assert_str(enemy.state_machine.current_state.name).is_equal("Fall")


func test_move_falls_when_airborne() -> void:
	enemy.grounded = false
	enemy.state_machine.change_state("Move")
	var move := _state("Move")

	move.physics_update_state(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Fall")


func test_fall_transitions_to_idle_on_landing() -> void:
	enemy.grounded = true
	enemy.state_machine.change_state("Fall")
	var fall := _state("Fall")

	fall.physics_update_state(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")


# ── Patrol ───────────────────────────────────────────────────────────

func test_patrol_flips_direction_at_patrol_limit() -> void:
	enemy.grounded = true
	enemy.facing_direction = Vector2.RIGHT
	enemy.global_position = Vector2(100.0, 0.0)
	enemy.state_machine.change_state("Patrol")
	var patrol := _state("Patrol") as EnemyPatrolState

	enemy.global_position = Vector2(100.0 + patrol.patrol_distance + 1.0, 0.0)
	patrol.physics_update_state(0.0)

	assert_float(enemy.facing_direction.x).is_equal(-1.0)
	assert_float(enemy.velocity.x).is_equal(-enemy.data.move_speed)


func test_patrol_flips_direction_on_wall() -> void:
	enemy.grounded = true
	enemy.facing_direction = Vector2.RIGHT
	enemy.global_position = Vector2.ZERO
	enemy.state_machine.change_state("Patrol")
	var patrol := _state("Patrol") as EnemyPatrolState

	enemy.on_wall = true
	patrol.physics_update_state(0.0)

	assert_float(enemy.facing_direction.x).is_equal(-1.0)


# ── Chase ────────────────────────────────────────────────────────────

func test_chase_moves_toward_target() -> void:
	enemy.grounded = true
	enemy.global_position = Vector2.ZERO
	enemy.target_position = Vector2(100.0, 0.0)
	enemy.state_machine.change_state("Chase")
	var chase := _state("Chase")

	chase.physics_update_state(0.0)

	assert_float(enemy.facing_direction.x).is_equal(1.0)
	assert_float(enemy.velocity.x).is_equal(enemy.data.move_speed)


func test_chase_switches_to_attack_inside_weapon_range() -> void:
	enemy.grounded = true
	enemy.global_position = Vector2.ZERO
	enemy.target_position = Vector2(10.0, 0.0)
	enemy.state_machine.change_state("Chase")
	var chase := _state("Chase")

	chase.physics_update_state(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Attack")


func test_chase_switches_to_patrol_when_target_is_lost() -> void:
	enemy.grounded = true
	enemy.target_position = Vector2.INF
	enemy.state_machine.change_state("Chase")
	var chase := _state("Chase")

	chase.physics_update_state(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Patrol")


# ── Attack ───────────────────────────────────────────────────────────

func test_attack_finishes_into_idle_when_grounded() -> void:
	enemy.grounded = true
	enemy.state_machine.change_state("Attack")

	enemy.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")


func test_attack_finishes_into_fall_when_airborne() -> void:
	enemy.grounded = false
	enemy.state_machine.change_state("Attack")

	enemy.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(enemy.state_machine.current_state.name).is_equal("Fall")


# ── Hurt ─────────────────────────────────────────────────────────────

func test_hurt_sets_and_clears_invulnerability() -> void:
	enemy.state_machine.change_state("Hurt")
	assert_bool(enemy.hurtbox.can_receive_hit()).is_false()

	enemy.state_machine.change_state("Idle")
	assert_bool(enemy.hurtbox.can_receive_hit()).is_true()


func test_hurt_transitions_to_dead_when_health_is_empty() -> void:
	enemy.state_machine.change_state("Hurt")
	var hurt := _state("Hurt")
	enemy.health.current_health = 0

	hurt.physics_update(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Dead")
	assert_bool(enemy.died).is_true()


# ── Dead ─────────────────────────────────────────────────────────────

func test_dead_calls_die_on_entry() -> void:
	enemy.state_machine.change_state("Dead")

	assert_bool(enemy.died).is_true()
