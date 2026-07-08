class_name InputCommand
extends RefCounted

var move_direction: float = 0.0

var commands: Array[Command] = []

func has_command(type: CommandType.Type) -> bool:
	for cmd in commands:
		if cmd.type == type:
			return true
	return false

func get_command(type: CommandType.Type) -> Command:
	for cmd in commands:
		if cmd.type == type:
			return cmd
	return null

func consume_command(type: CommandType.Type) -> bool:
	for i in range(commands.size()):
		if commands[i].type == type:
			commands.remove_at(i)
			return true
	return false

func add_command(cmd: Command) -> void:
	commands.append(cmd)
