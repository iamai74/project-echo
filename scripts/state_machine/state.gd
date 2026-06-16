class_name State
extends Node

var actor: Actor
var state_machine: StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func update(delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
	
func change_state(state_name: StringName) -> void:
	state_machine.change_state(state_name)
