## Actor behaviour tests.
## Covers: knockback edge cases, defeated-actor hit handling, coyote time,
## jump-count reset and airborne gravity.
extends GdUnitTestSuite


const Fixture = preload("res://scripts/test/fixtures/actor_state_fixture.gd")


var actor


func before_test() -> void:
	actor = auto_free(Fixture.build_player())
	Fixture.add_player_states(actor)
	Fixture.start(actor)
	actor._connect_signals()


# ── Hit flow ─────────────────────────────────────────────────────────

func test_zero_knockback_hit_does_not_change_velocity() -> void:
	actor.velocity = Vector2(50.0, 0.0)

	actor.hurtbox.receive_hit(AttackData.new(10, 0.0))

	assert_vector(actor.velocity).is_equal(Vector2(50.0, 0.0))


func test_defeated_actor_does_not_enter_hurt_state() -> void:
	actor.health.current_health = 0

	actor.hurtbox.receive_hit(AttackData.new(10, 100.0, null, Vector2.LEFT))

	assert_str(actor.state_machine.current_state.name).is_equal("Idle")


# ── Coyote time and jumps ────────────────────────────────────────────

func test_coyote_time_is_set_on_floor_and_decays_in_air() -> void:
	var player = auto_free(Fixture.StubPlayer.new())
	player.data = ActorData.new()

	player.grounded = true
	player._update_coyote_timer(0.05)
	assert_float(player.coyote_timer).is_equal(player.data.coyote_time)

	player.grounded = false
	player._update_coyote_timer(0.05)
	assert_float(player.coyote_timer).is_equal_approx(player.data.coyote_time - 0.05, 0.0001)


func test_coyote_time_does_not_decay_below_zero() -> void:
	var player = auto_free(Fixture.StubPlayer.new())
	player.data = ActorData.new()
	player.grounded = false
	player.coyote_timer = 0.01

	player._update_coyote_timer(1.0)

	assert_float(player.coyote_timer).is_zero()


func test_jump_count_resets_on_landing() -> void:
	var player = auto_free(Fixture.StubPlayer.new())
	player.data = ActorData.new()
	player.jump_count = 0
	player.grounded = true

	player._update_coyote_timer(0.0)

	assert_int(player.jump_count).is_equal(player.data.max_jumps)


# ── Gravity ──────────────────────────────────────────────────────────

func test_gravity_is_applied_only_while_airborne() -> void:
	var player = auto_free(Fixture.StubPlayer.new())
	player.data = ActorData.new()

	player.grounded = false
	player.velocity.y = 0.0
	player._apply_gravity(0.5)
	assert_float(player.velocity.y).is_equal(player.data.gravity * 0.5)

	player.grounded = true
	player.velocity.y = 0.0
	player._apply_gravity(0.5)
	assert_float(player.velocity.y).is_zero()
