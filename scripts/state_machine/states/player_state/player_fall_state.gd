class_name PlayerFallState
extends PlayerState


func physics_update_state(_delta: float) -> void:

	if player.is_on_floor():
		change_state("Idle")
		return

	var direction := input_component.get_command().move_direction
	player.move(direction)
