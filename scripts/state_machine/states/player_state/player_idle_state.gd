class_name PlayerIdleState
extends PlayerState

func physics_update_state(_delta: float) -> void:

	if not player.is_on_floor():
		change_state("Fall")
		return

	if abs(input_component.get_command().move_direction) > 0.01:
		change_state("Move")
