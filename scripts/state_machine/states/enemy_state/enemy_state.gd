class_name EnemyState
extends State

var enemy: Enemy

var health_component: HealthComponent
var hitbox_component: HitboxComponent
var hurtbox_component: HurtboxComponent


func setup() -> void:
	enemy = actor as Enemy

	health_component = enemy.health
	hurtbox_component = enemy.hurtbox


func is_grounded() -> bool:
	return enemy.is_on_floor()


func is_falling() -> bool:
	return enemy.velocity.y > 0.0


func is_dead() -> bool:
	return not health_component.is_alive()


func has_movement_input() -> bool:
	# update when can move
	return false


func on_attack_finished(attack: AttackDefinition) -> void:
	pass


func physics_update(delta: float) -> void:
	var previous_state := state_machine.current_state
	_handle_global_transitions()

	if state_machine.current_state != previous_state:
		return

	physics_update_state(delta)


func physics_update_state(_delta: float) -> void:
	pass


func _handle_global_transitions() -> void:
	if is_dead():
		change_state("Dead")
		return

	var current_state_name = enemy.state_machine.current_state.name
	if current_state_name == "Attack" or current_state_name == "Hurt":
		return
