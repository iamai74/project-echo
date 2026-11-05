## Shared fixture for actor/state tests.
##
## Builds a real Player or Enemy with stub components so state behaviour can be
## exercised without loading full game scenes. The stubs only override the
## environment-dependent parts (floor/wall contact, input held state, weapon
## side effects) and keep the production actor logic intact.
extends RefCounted


class StubPlayer:
	extends Player

	var grounded := false
	var on_wall := false
	var died := false
	var air_attack_started := false
	var attack_finished := false

	func is_grounded() -> bool:
		return grounded

	func is_touching_wall() -> bool:
		return on_wall

	func die() -> void:
		died = true

	func start_air_attack() -> void:
		air_attack_started = true

	func is_attack_finished() -> bool:
		return attack_finished


class StubEnemy:
	extends Enemy

	var grounded := false
	var on_wall := false
	var died := false
	var target_position := Vector2.INF

	func is_grounded() -> bool:
		return grounded

	func is_touching_wall() -> bool:
		return on_wall

	func die() -> void:
		died = true

	func get_target_position() -> Vector2:
		return target_position


class StubWalker:
	extends Walker

	var grounded := false
	var on_wall := false
	var died := false
	var target_position := Vector2.INF

	func is_grounded() -> bool:
		return grounded

	func is_touching_wall() -> bool:
		return on_wall

	func die() -> void:
		died = true

	func get_target_position() -> Vector2:
		return target_position


class StubInputComponent:
	extends InputComponent

	var held_actions: Dictionary = {}

	func is_action_held(action: String) -> bool:
		return held_actions.get(action, false)


class StubWeaponComponent:
	extends WeaponComponent

	var started_attacks: Array[AttackType.Type] = []

	func start_attack(type: AttackType.Type) -> void:
		started_attacks.append(type)

	func is_attacking() -> bool:
		return not started_attacks.is_empty()


static func build_player() -> StubPlayer:
	var player := StubPlayer.new()
	player.data = ActorData.new()

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	player.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	player.add_child(hurtbox)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	player.add_child(state_machine)

	var input := StubInputComponent.new()
	input.name = "InputComponent"
	player.add_child(input)

	var weapon := StubWeaponComponent.new()
	weapon.name = "WeaponComponent"
	player.add_child(weapon)

	player.health = health
	player.hurtbox = hurtbox
	player.state_machine = state_machine
	player.input_component = input
	player.weapon_component = weapon

	health.initialize(player.data.max_health)
	return player


static func build_enemy() -> StubEnemy:
	var enemy := StubEnemy.new()
	enemy.data = ActorData.new()

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	enemy.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	enemy.add_child(hurtbox)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	enemy.add_child(state_machine)

	var weapon := StubWeaponComponent.new()
	weapon.name = "WeaponComponent"
	enemy.add_child(weapon)

	enemy.health = health
	enemy.hurtbox = hurtbox
	enemy.state_machine = state_machine
	enemy.weapon_component = weapon

	health.initialize(enemy.data.max_health)
	return enemy


static func build_walker() -> StubWalker:
	var walker := StubWalker.new()
	walker.data = ActorData.new()

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	walker.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	walker.add_child(hurtbox)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	walker.add_child(state_machine)

	var weapon := StubWeaponComponent.new()
	weapon.name = "WeaponComponent"
	walker.add_child(weapon)

	walker.health = health
	walker.hurtbox = hurtbox
	walker.state_machine = state_machine
	walker.weapon_component = weapon

	health.initialize(walker.data.max_health)
	return walker


static func add_player_states(player: StubPlayer) -> void:
	add_state(player.state_machine, "Idle", PlayerIdleState.new())
	add_state(player.state_machine, "Move", PlayerMoveState.new())
	add_state(player.state_machine, "Fall", PlayerFallState.new())
	add_state(player.state_machine, "Jump", PlayerJumpState.new())
	add_state(player.state_machine, "Attack", PlayerAttackState.new())
	add_state(player.state_machine, "Dead", PlayerDeadState.new())
	add_state(player.state_machine, "Hurt", PlayerHurtState.new())
	add_state(player.state_machine, "JumpAttack", PlayerJumpAttackState.new())
	add_state(player.state_machine, "Dash", State.new())


static func add_enemy_states(enemy: Enemy) -> void:
	add_state(enemy.state_machine, "Idle", EnemyIdleState.new())
	add_state(enemy.state_machine, "Move", EnemyMoveState.new())
	add_state(enemy.state_machine, "Fall", EnemyFallState.new())
	add_state(enemy.state_machine, "Patrol", EnemyPatrolState.new())
	add_state(enemy.state_machine, "Chase", EnemyChaseState.new())
	add_state(enemy.state_machine, "Attack", EnemyAttackState.new())
	add_state(enemy.state_machine, "Hurt", EnemyHurtState.new())
	add_state(enemy.state_machine, "Dead", EnemyDeadState.new())


static func add_state(state_machine: StateMachine, state_name: String, state: State) -> void:
	state.name = state_name
	state_machine.add_child(state)


static func start(player: Player, initial_state: String = "Idle") -> void:
	player.state_machine.initialize(player)
	player.state_machine.setup_states()
	player.state_machine.start(initial_state)


static func start_enemy(enemy: Enemy, initial_state: String = "Idle") -> void:
	enemy.state_machine.initialize(enemy)
	enemy.state_machine.setup_states()
	enemy.state_machine.start(initial_state)


static func start_walker(walker: Walker, initial_state: String = "Idle") -> void:
	walker.state_machine.initialize(walker)
	walker.state_machine.setup_states()
	walker.state_machine.start(initial_state)
