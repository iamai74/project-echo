## InputCommand and Command unit tests.
## Covers: add, find, consume, missing command, ordering, empty state.
extends GdUnitTestSuite


var cmd: InputCommand


func before_test() -> void:
	cmd = InputCommand.new()


func test_empty_state_has_no_commands() -> void:
	assert_int(cmd.commands.size()).is_zero()
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_false()
	assert_object(cmd.get_command(CommandType.Type.JUMP)).is_null()


func test_add_command() -> void:
	var jump = Command.new(CommandType.Type.JUMP)
	cmd.add_command(jump)
	assert_int(cmd.commands.size()).is_equal(1)
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_true()


func test_add_multiple_commands() -> void:
	cmd.add_command(Command.new(CommandType.Type.JUMP))
	cmd.add_command(Command.new(CommandType.Type.ATTACK))
	cmd.add_command(Command.new(CommandType.Type.MOVE))
	assert_int(cmd.commands.size()).is_equal(3)
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_true()
	assert_bool(cmd.has_command(CommandType.Type.ATTACK)).is_true()
	assert_bool(cmd.has_command(CommandType.Type.MOVE)).is_true()


func test_has_command_returns_false_for_missing() -> void:
	cmd.add_command(Command.new(CommandType.Type.JUMP))
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_true()
	assert_bool(cmd.has_command(CommandType.Type.DASH)).is_false()


func test_get_command_returns_command() -> void:
	var attack = Command.new(CommandType.Type.ATTACK, Vector2.RIGHT)
	cmd.add_command(attack)
	var found = cmd.get_command(CommandType.Type.ATTACK)
	assert_object(found).is_not_null()
	assert_that(found.type).is_equal(CommandType.Type.ATTACK)
	assert_vector(found.direction).is_equal(Vector2.RIGHT)


func test_get_command_returns_null_when_missing() -> void:
	assert_object(cmd.get_command(CommandType.Type.INTERACT)).is_null()


func test_consume_command_removes_it() -> void:
	cmd.add_command(Command.new(CommandType.Type.JUMP))
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_true()
	assert_bool(cmd.consume_command(CommandType.Type.JUMP)).is_true()
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_false()
	assert_int(cmd.commands.size()).is_zero()


func test_consume_missing_command_returns_false() -> void:
	assert_bool(cmd.consume_command(CommandType.Type.USE_ITEM)).is_false()


func test_consume_preserves_other_commands() -> void:
	cmd.add_command(Command.new(CommandType.Type.JUMP))
	cmd.add_command(Command.new(CommandType.Type.ATTACK))
	cmd.consume_command(CommandType.Type.JUMP)
	assert_bool(cmd.has_command(CommandType.Type.JUMP)).is_false()
	assert_bool(cmd.has_command(CommandType.Type.ATTACK)).is_true()
	assert_int(cmd.commands.size()).is_equal(1)


func test_command_ordering_preserved() -> void:
	cmd.add_command(Command.new(CommandType.Type.MOVE))
	cmd.add_command(Command.new(CommandType.Type.JUMP))
	cmd.add_command(Command.new(CommandType.Type.ATTACK))
	assert_that(cmd.commands[0].type).is_equal(CommandType.Type.MOVE)
	assert_that(cmd.commands[1].type).is_equal(CommandType.Type.JUMP)
	assert_that(cmd.commands[2].type).is_equal(CommandType.Type.ATTACK)


func test_command_direction_and_metadata() -> void:
	var direction = Vector2.LEFT
	var metadata = {"key": "value"}
	var c = Command.new(CommandType.Type.MOVE, direction, metadata)
	assert_that(c.type).is_equal(CommandType.Type.MOVE)
	assert_vector(c.direction).is_equal(direction)
	assert_dict(c.metadata).is_equal(metadata)


func test_command_default_direction_is_zero() -> void:
	var c = Command.new(CommandType.Type.JUMP)
	assert_vector(c.direction).is_equal(Vector2.ZERO)


func test_command_default_metadata_is_empty() -> void:
	var c = Command.new(CommandType.Type.JUMP)
	assert_int(c.metadata.size()).is_zero()
