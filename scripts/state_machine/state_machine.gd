class_name StateMachine
extends Node

var states: Dictionary = {}
var actor: Actor
var current_state: State
var previous_state: State


func initialize(owner: Actor) -> void:
	actor = owner

	for child in get_children():
		if child is State:
			states[child.name] = child

			child.actor = actor
			child.state_machine = self


func setup_states() -> void:
	for state in states.values():
		if state.has_method("setup"):
			state.setup()


func start(initial_state_name: StringName) -> void:
	if not states.has(initial_state_name):
		push_error("State not found: " + initial_state_name)
		return

	current_state = states[initial_state_name]
	current_state.enter()


func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func handle_attack_finished(attack: AttackDefinition) -> void:
	current_state.on_attack_finished(attack)


func change_state(new_state_name: StringName) -> void:
	if not states.has(new_state_name):
		push_error("State not found: " + new_state_name)
		return

	var new_state: State = states[new_state_name]

	if new_state == current_state:
		return

	previous_state = current_state

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
