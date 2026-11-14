## Actor hit-flow integration tests.
## Covers: Hitbox -> Hurtbox -> HealthComponent flow.
extends GdUnitTestSuite

const ActorFixture = preload("res://test/fixtures/actor_fixture.gd")

var actor: Actor
var health: HealthComponent
var hurtbox: HurtboxComponent
var state_machine: StateMachine
var data: ActorData

## Attacker actor with HitboxComponent.
var attacker: Actor
var attacker_hurtbox: HurtboxComponent
var attacker_state_machine: StateMachine
var attacker_hitbox: HitboxComponent

## Defender actor with HealthComponent and HurtboxComponent.
var defender: Actor
var defender_health: HealthComponent
var defender_hurtbox: HurtboxComponent
var defender_state_machine: StateMachine

var _test_parameters := [
	["RectangleShape2D"],
	["CapsuleShape2D"]
]

func before_test() -> void:
	data = ActorData.new()
	data.max_health = 100

	actor = auto_free(ActorFixture.build_actor(data))
	health = actor.health
	hurtbox = actor.hurtbox
	state_machine = actor.state_machine

	ActorFixture.add_hurt_and_dead_states(actor)

	actor._initialize_components()
	actor._connect_signals()
	state_machine.initialize(actor)


func test_hitbox_health_integration(
	shape_type: String,
	_test_parameters := _test_parameters
) -> void:
	# Build attacker: Actor scene with Health + Hitbox
	var attacker_data := ActorData.new()
	attacker_data.max_health = 100
	attacker = auto_free(ActorFixture.build_actor(attacker_data))
	attacker.name = "Attacker"
	attacker_state_machine = attacker.state_machine
	attacker_hurtbox = attacker.hurtbox
	ActorFixture.add_hurt_and_dead_states(attacker)

	# Add Hitbox with explicit layer/mask
	attacker_hitbox = HitboxComponent.new()
	attacker_hitbox.name = "HitboxComponent"
	attacker_hitbox.collision_layer = 4
	attacker_hitbox.collision_mask = 8
	attacker.add_child(attacker_hitbox)

	# Add collision shape to hitbox
	var attacker_shape := CollisionShape2D.new()
	attacker_shape.name = "CollisionShape2D"
	if shape_type == "RectangleShape2D":
		attacker_shape.shape = RectangleShape2D.new()
		attacker_shape.shape.size = Vector2(30, 50)
	else:
		attacker_shape.shape = CapsuleShape2D.new()
		attacker_shape.shape.radius = 16.0
		attacker_shape.shape.height = 95.0
	attacker_hitbox.add_child(attacker_shape)

	# Build defender: Actor scene with Health + Hurtbox
	var defender_data := ActorData.new()
	defender_data.max_health = 100
	defender = auto_free(ActorFixture.build_actor(defender_data))
	defender.name = "Defender"
	defender_health = defender.health
	defender_hurtbox = defender.hurtbox
	defender_hurtbox.collision_layer = 8
	defender_hurtbox.collision_mask = 4
	defender_state_machine = defender.state_machine
	ActorFixture.add_hurt_and_dead_states(defender)

	# Add collision shape to hurtbox
	var defender_shape := CollisionShape2D.new()
	defender_shape.name = "CollisionShape2D"
	if shape_type == "RectangleShape2D":
		defender_shape.shape = RectangleShape2D.new()
		defender_shape.shape.size = Vector2(30, 50)
	else:
		defender_shape.shape = CapsuleShape2D.new()
		defender_shape.shape.radius = 16.0
		defender_shape.shape.height = 95.0
	defender_hurtbox.add_child(defender_shape)

	# Adding the actors to the tree runs Actor._ready, which resolves the
	# @onready component fields and wires health.died -> _on_died and
	# hurtbox.hit_received -> _on_hit_received through the real Actor path.
	add_child(attacker)
	add_child(defender)

	# State machines must be initialized manually: Actor._ready only assigns
	# state.actor, it does not populate the state lookup used by start().
	attacker_state_machine.initialize(attacker)
	defender_state_machine.initialize(defender)

	# Wait for state machine to initialize
	await get_tree().process_frame

	# Position actors at the same global position (shapes will overlap)
	attacker.global_position = Vector2.ZERO
	defender.global_position = Vector2.ZERO

	# Wait for physics frame to allow collision detection
	await get_tree().physics_frame

	# Start monitoring before the hit so GdUnit4 captures the emissions.
	monitor_signals(attacker_hitbox, false)
	monitor_signals(defender_hurtbox, false)

	# Activate hitbox with attack
	var attack = auto_free(AttackData.new(20))
	attacker_hitbox.activate(attack)

	# Enabling monitoring does not register the existing overlap synchronously:
	# the physics server reports it on the next physics step, when area_entered
	# routes the hit through the real hurtbox -> actor -> health chain.
	await get_tree().physics_frame

	# Assert: defender's health dropped by exactly the attack damage
	assert_int(defender_health.current_health).is_equal(80)

	# Assert: hit_target signal was emitted on the hitbox (arg = hurtbox)
	await assert_signal(attacker_hitbox).is_emitted("hit_target", defender_hurtbox)

	# Assert: hit_received signal was emitted on the hurtbox (arg = attack)
	await assert_signal(defender_hurtbox).is_emitted("hit_received", attack)

	# Wait for dedup to suppress repeat hits
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Assert: after two physics frames, health does not change (dedup worked)
	assert_int(defender_health.current_health).is_equal(80)


func test_hit_reduces_health() -> void:
	var attack = AttackData.new(20)
	# Simulate the hit on the hurtbox
	hurtbox.receive_hit(attack)

	assert_int(health.current_health).is_equal(80)

func test_hit_causes_death_when_health_reaches_zero() -> void:
	var attack = AttackData.new(100)
	# Simulate the hit on the hurtbox
	hurtbox.receive_hit(attack)

	assert_bool(health.is_alive()).is_false()

func test_hit_triggers_knockback() -> void:
	# We need to set up a direction for knockback
	var attack = AttackData.new(10)
	attack.direction = Vector2.LEFT
	attack.knockback_force = 100.0

	actor.velocity = Vector2.ZERO

	# Simulate the hit
	hurtbox.receive_hit(attack)

	# Check if velocity was modified (knockback)
	assert_float(actor.velocity.x).is_equal(-100.0)
