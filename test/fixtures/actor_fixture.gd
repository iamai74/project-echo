## Shared fixture for plain Actor component tests.
##
## Builds an Actor with the component children that Actor._ready() expects and
## assigns the @onready fields so callers can use the actor before it enters the
## tree. The fixture never adds the actor to the scene tree.
extends RefCounted


static func build_actor(data: ActorData = null) -> Actor:
	var actor := Actor.new()
	actor.data = data if data != null else ActorData.new()

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	actor.add_child(hurtbox)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	actor.add_child(state_machine)

	actor.health = health
	actor.hurtbox = hurtbox
	actor.state_machine = state_machine
	return actor


static func build_actor_with_weapon(
	data: ActorData = null, weapon_data: WeaponData = null
) -> Actor:
	var actor := build_actor(data)

	var weapon := WeaponComponent.new()
	weapon.name = "WeaponComponent"
	weapon.weapon_data = weapon_data if weapon_data != null else WeaponData.new()

	var hitbox := HitboxComponent.new()
	hitbox.name = "HitboxComponent"

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	hitbox.add_child(shape)

	weapon.add_child(hitbox)
	actor.add_child(weapon)
	actor.weapon_component = weapon
	return actor


static func add_hurt_and_dead_states(actor: Actor) -> void:
	for state_name in ["Hurt", "Dead"]:
		var state := State.new()
		state.name = state_name
		actor.state_machine.add_child(state)
