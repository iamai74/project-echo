## Actor hit-flow integration tests.
## Covers: Hitbox -> Hurtbox -> HealthComponent flow.
extends GdUnitTestSuite

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

	actor = auto_free(Actor.new())
	actor.data = data

	health = HealthComponent.new()
	hurtbox = HurtboxComponent.new()
	state_machine = StateMachine.new()

	actor.add_child(health)
	actor.add_child(hurtbox)
	actor.add_child(state_machine)

	# Minimal states so hit responses can transition without errors.
	var hurt_state := State.new()
	hurt_state.name = "Hurt"
	state_machine.add_child(hurt_state)

	var dead_state := State.new()
	dead_state.name = "Dead"
	state_machine.add_child(dead_state)

	# Manually satisfy the @onready requirements for the test.
	actor.health = health
	actor.hurtbox = hurtbox
	actor.state_machine = state_machine

	# Manually call the initialization methods.
	actor._initialize_components()
	actor._connect_signals()
	state_machine.initialize(actor)


func test_hitbox_health_integration(
	shape_type: String,
	_test_parameters := _test_parameters
) -> void:
	# Build attacker: Actor scene with Health + Hitbox
	attacker = auto_free(Actor.new())
	attacker.name = "Attacker"
	attacker.data = ActorData.new()
	attacker.data.max_health = 100

	# Add Health
	attacker.health = HealthComponent.new()
	attacker.health.name = "HealthComponent"
	attacker.health.initialize(100)  # Initialize health
	attacker.add_child(attacker.health)

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

	# Add Hurtbox to attacker (as attacker's hurtbox - will be unused)
	attacker_hurtbox = HurtboxComponent.new()
	attacker_hurtbox.name = "HurtboxComponent"
	attacker.add_child(attacker_hurtbox)

	# Add StateMachine with Hurt and Dead states
	attacker_state_machine = StateMachine.new()
	attacker_state_machine.name = "StateMachine"
	attacker.add_child(attacker_state_machine)

	var hurt_state := State.new()
	hurt_state.name = "Hurt"
	attacker_state_machine.add_child(hurt_state)

	var dead_state := State.new()
	dead_state.name = "Dead"
	attacker_state_machine.add_child(dead_state)

	# Build defender: Actor scene with Health + Hurtbox
	defender = auto_free(Actor.new())
	defender.name = "Defender"
	defender.data = ActorData.new()
	defender.data.max_health = 100

	# Add Health
	defender_health = HealthComponent.new()
	defender_health.name = "HealthComponent"
	defender_health.initialize(100)  # Initialize health
	defender.add_child(defender_health)

	# Add Hurtbox with explicit layer/mask
	defender_hurtbox = HurtboxComponent.new()
	defender_hurtbox.name = "HurtboxComponent"
	defender_hurtbox.collision_layer = 8
	defender_hurtbox.collision_mask = 4
	defender.add_child(defender_hurtbox)

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

	# Add StateMachine with Hurt and Dead states
	defender_state_machine = StateMachine.new()
	defender_state_machine.name = "StateMachine"
	defender.add_child(defender_state_machine)

	var def_hurt_state := State.new()
	def_hurt_state.name = "Hurt"
	defender_state_machine.add_child(def_hurt_state)

	var def_dead_state := State.new()
	def_dead_state.name = "Dead"
	defender_state_machine.add_child(def_dead_state)

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
