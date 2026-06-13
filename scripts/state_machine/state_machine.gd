class_name StateMachine
extends Node

signal state_changed(old_state: State, new_state: State)

var current_state: State
var previous_state: State

func change_state(new_state: State) -> void:
	if not new_state or current_state == new_state:
		return
	
	if current_state:
		current_state.exit()
	
	previous_state = current_state
	current_state = new_state
	current_state.enter()
	
	state_changed.emit(previous_state, current_state)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
