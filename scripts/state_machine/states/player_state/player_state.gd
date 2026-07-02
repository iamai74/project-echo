class_name PlayerState
extends State

var player: Player

var input_component: InputComponent
var health_component: HealthComponent
var hitbox_component: HitboxComponent
var hurtbox_component: HurtboxComponent


func setup() -> void:

	player = actor as Player

	input_component = player.input_component
	health_component = player.health
	#hitbox_component = player.hitbox
	hurtbox_component = player.hurtbox


func command() -> InputCommand:
	return input_component.get_command()


func has_movement_input() -> bool:
	return abs(command().move_direction) > 0.01


func movement_direction() -> float:
	return command().move_direction


func consume_jump() -> bool:
	return command().consume_jump()


func consume_attack() -> bool:
	return command().consume_attack()


func consume_dash() -> bool:
	return command().consume_dash()


func is_grounded() -> bool:
	return player.is_on_floor()


func is_falling() -> bool:
	return player.velocity.y > 0.0


func is_dead() -> bool:
	return not health_component.is_alive()
	
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

	var current_state_name = player.state_machine.current_state.name
	if current_state_name == "Attack" or current_state_name == "Hurt":
		return

	var cmd := input_component.get_command()

	if cmd.consume_jump() and player.jump_count > 0:
		player.jump_count -= 1
		change_state("Jump")
		return

	if cmd.consume_attack():
		change_state("Attack")
		return

	if cmd.consume_dash():
		change_state("Dash")
		return
