class_name InputCommand
extends RefCounted

var move_direction: float = 0.0

var jump_held: bool = false
var attack_held: bool = false

var jump_buffer: float = 0.0
var attack_buffer: float = 0.0
var dash_buffer: float = 0.0
var interact_buffer: float = 0.0


func has_jump() -> bool:
	return jump_buffer > 0.0


func has_attack() -> bool:
	return attack_buffer > 0.0


func has_dash() -> bool:
	return dash_buffer > 0.0


func has_interact() -> bool:
	return interact_buffer > 0.0


func consume_jump() -> bool:
	if jump_buffer <= 0.0:
		return false

	jump_buffer = 0.0
	return true

func consume_attack() -> bool:
	if attack_buffer <= 0.0:
		return false

	attack_buffer = 0.0
	return true

func consume_dash() -> bool:
	if dash_buffer <= 0.0:
		return false

	dash_buffer = 0.0
	return true

func consume_interact() -> bool:
	if interact_buffer <= 0.0:
		return false

	interact_buffer = 0.0
	return true
