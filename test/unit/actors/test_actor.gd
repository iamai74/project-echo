## Actor unit tests.
## Covers: component init, signal connection, attack delegation, movement, jump, facing direction, utility methods, knockback, and death state.
extends GdUnitTestSuite


var actor: Actor
var health: HealthComponent
var hurtbox: HurtboxComponent
var state_machine: StateMachine
var weapon: WeaponComponent
var sprite: Sprite2D
var data: ActorData


func before_test() -> void:
	actor = auto_free(Actor.new()) as Actor
	actor.name = "Actor"
	
	data = ActorData.new()
	data.max_health = 5
	data.move_speed = 200.0
	data.jump_velocity = -400.0
	data.gravity = 1000.0
	data.coyote_time = 0.1
	data.max_jumps = 1
	actor.data = data
	
	health = HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)
	
	hurtbox = HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	actor.add_child(hurtbox)
	
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	actor.add_child(state_machine)
	
	var dead_state := State.new()
	dead_state.name = "Dead"
	state_machine.add_child(dead_state)
	
	var hurt_state := State.new()
	hurt_state.name = "Hurt"
	state_machine.add_child(hurt_state)
	
	weapon = WeaponComponent.new()
	weapon.name = "WeaponComponent"
	
	# Setup weapon_data properly so it's not null and has attacks
	var w_data = WeaponData.new()
	var attack_def = AttackDefinition.new()
	attack_def.attack_type = AttackType.Type.LIGHT
	attack_def.damage = 1
	attack_def.knockback_force = 10
	attack_def.startup = 0.1
	attack_def.active = 0.1
	attack_def.recovery = 0.1
	w_data.attacks.append(attack_def)
	w_data.initialize()
	weapon.weapon_data = w_data
	
	actor.add_child(weapon)
	
	var hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	weapon.add_child(hitbox)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	hitbox.add_child(shape)
	
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	actor.add_child(sprite)
	
	add_child(actor)
	
	state_machine.initialize(actor)


# --- Initialisation ---

func test_ready_initializes_components_and_connects_signals() -> void:
	# Check if signals are connected by triggering them
	monitor_signals(health, false)
	monitor_signals(hurtbox, false)
	
	# Triggering health.died should start Dead state
	health.died.emit()
	assert_str(state_machine.current_state.name).is_equal("Dead")
	
	# Triggering hurtbox.hit_received should apply damage and start Hurt state (if alive)
	var attack = AttackData.new(1)
	hurtbox.hit_received.emit(attack)
	assert_int(health.current_health).is_equal(4)
	assert_str(state_machine.current_state.name).is_equal("Hurt")


# --- Attack Delegation ---

func test_attack_and_light_attack_delegate_to_weapon_component() -> void:
	# We need some AttackDefinition for the weapon component to not error out.
	var attack_def = AttackDefinition.new()
	attack_def.attack_type = AttackType.Type.LIGHT
	var weapon_data = WeaponData.new()
	weapon_data.attacks.append(attack_def)
	weapon_data.initialize()
	weapon.weapon_data = weapon_data
	
	actor.attack(AttackType.Type.LIGHT)
	assert_bool(weapon.is_attacking()).is_true()
	
	actor.light_attack()
	assert_bool(weapon.is_attacking()).is_true()


func test_attack_delegation_works_even_without_weapon_component() -> void:
	actor.remove_child(weapon)
	weapon.queue_free()
	weapon = null
	
	# This should not crash
	actor.attack(AttackType.Type.LIGHT)
	actor.light_attack()
	assert_bool(true).is_true()


# --- Movement and Physics ---

func test_movement_applies_velocity() -> void:
	actor.move(1.0)
	assert_float(actor.velocity.x).is_equal(200.0)
	
	actor.move(-1.0)
	assert_float(actor.velocity.x).is_equal(-200.0)
	
	actor.move(0.0)
	assert_float(actor.velocity.x).is_equal(0.0)


func test_jump_applies_velocity() -> void:
	actor.jump()
	assert_float(actor.velocity.y).is_equal(-400.0)


func test_facing_direction_and_sprite_flip_behaviour() -> void:
	# Initial state
	assert_vector(actor.facing_direction).is_equal(Vector2.RIGHT)
	
	# Move right
	actor.velocity.x = 200.0
	actor._physics_process(0.016)
	assert_vector(actor.facing_direction).is_equal(Vector2.RIGHT)
	assert_bool(sprite.flip_h).is_false()
	
	# Move left
	actor.velocity.x = -200.0
	actor._physics_process(0.016)
	assert_vector(actor.facing_direction).is_equal(Vector2.LEFT)
	assert_bool(sprite.flip_h).is_true()
	
	# Stop moving
	actor.velocity.x = 0.0
	actor._physics_process(0.016)
	# If velocity.x == 0, it doesn't update. So it should stay LEFT if it was LEFT.
	
	actor.velocity.x = -200.0
	actor._physics_process(0.016)
	assert_bool(sprite.flip_h).is_true()
	
	actor.velocity.x = 0.0
	actor._physics_process(0.016)
	assert_bool(sprite.flip_h).is_true() # Still true because it didn't enter the if block.


# --- Utility Methods ---

func test_utility_methods_return_correct_values() -> void:
	# distance_to
	var other_actor = Actor.new()
	other_actor.global_position = Vector2(100, 0)
	actor.global_position = Vector2(0, 0)
	assert_float(actor.distance_to(other_actor)).is_equal(100.0)
	other_actor.free()
	
	# set_invulnerable
	actor.set_invulnerable(true)
	assert_bool(hurtbox.can_receive_hit()).is_false()
	
	actor.set_invulnerable(false)
	assert_bool(hurtbox.can_receive_hit()).is_true()


# --- Knockback and Damage ---

func test_knockback_reaction_applies_velocity() -> void:
	var attack = AttackData.new(0, 100.0, null, Vector2.LEFT)
	
	actor.velocity = Vector2.ZERO
	actor._knockback_reaction(attack)
	
	assert_vector(actor.velocity).is_equal(Vector2.LEFT * 100.0)


func test_state_handling_when_health_is_zero() -> void:
	# First, make it dead
	health.current_health = 0
	health.died.emit()
	assert_str(state_machine.current_state.name).is_equal("Dead")
	
	# If we try to hit it while dead, it should not change state to Hurt
	var attack = AttackData.new(1)
	hurtbox.hit_received.emit(attack)
	
	assert_str(state_machine.current_state.name).is_equal("Dead")
