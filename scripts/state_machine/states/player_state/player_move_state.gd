class_name PlayerMoveState
extends PlayerState


func physics_update_state(_delta: float) -> void:
	if not player.is_on_floor():
		change_state("Fall")
		return

	var direction := input_component.get_command().move_direction
	player.move(direction)

	if abs(direction) <= 0.01:
		change_state("Idle")
