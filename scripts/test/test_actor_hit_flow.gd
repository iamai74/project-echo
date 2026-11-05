## Actor hit-flow integration tests.
## Covers: Hitbox -> Hurtbox -> HealthComponent flow.
extends GdUnitTestSuite

var actor: Actor
var health: HealthComponent
var hurtbox: HurtboxComponent
var state_machine: StateMachine
var data: ActorData

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
