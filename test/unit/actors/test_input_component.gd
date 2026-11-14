## InputComponent unit tests.
## Covers: deadzone application, command creation structure, input enabled/disabled.
extends GdUnitTestSuite


var input_comp: InputComponent


func before_test() -> void:
	input_comp = auto_free(InputComponent.new())
	input_comp.stick_deadzone = 0.2


# Failure-path cleanup: release every action this file presses so an aborted assertion cannot leak pressed input into later tests.
const TESTED_ACTIONS := ["jump", "attack", "dash", "interact", "move_left", "move_right"]


func after_test() -> void:
	for action in TESTED_ACTIONS:
		Input.action_release(action)


# --- Deadzone ---

func test_deadzone_zero_input_returns_zero() -> void:
	# Value below deadzone
	var result = input_comp._apply_deadzone(0.1)
	assert_float(result).is_equal(0.0)


func test_deadzone_negative_below_deadzone_returns_zero() -> void:
	var result = input_comp._apply_deadzone(-0.1)
	assert_float(result).is_equal(0.0)


func test_deadzone_exact_deadzone_returns_zero() -> void:
	# At exactly the deadzone boundary
	var result = input_comp._apply_deadzone(0.2)
	assert_float(result).is_equal(0.0)


func test_deadzone_full_positive_returns_one() -> void:
	var result = input_comp._apply_deadzone(1.0)
	assert_float(result).is_equal(1.0)


func test_deadzone_full_negative_returns_minus_one() -> void:
	var result = input_comp._apply_deadzone(-1.0)
	assert_float(result).is_equal(-1.0)


func test_deadzone_partial_positive_returns_scaled() -> void:
	# 0.6 with deadzone 0.2: (0.6 - 0.2) / (1.0 - 0.2) = 0.4 / 0.8 = 0.5
	var result = input_comp._apply_deadzone(0.6)
	assert_float(result).is_equal_approx(0.5, 0.0001)


func test_deadzone_custom_deadzone() -> void:
	input_comp.stick_deadzone = 0.5
	# 0.7 with deadzone 0.5: (0.7 - 0.5) / (1.0 - 0.5) = 0.2 / 0.5 = 0.4
	var result = input_comp._apply_deadzone(0.7)
	assert_float(result).is_equal_approx(0.4, 0.0001)


func test_fuzz_deadzone_output_stays_normalized(
	fuzzer_axis := Fuzzers.rangei(-1000, 1000),
	_fuzzer_iterations := 50,
	_fuzzer_seed := 1234) -> void:
	var axis: float = fuzzer_axis.next_value() / 1000.0
	var result := input_comp._apply_deadzone(axis)

	assert_float(result).is_between(-1.0, 1.0)
	if absf(axis) <= input_comp.stick_deadzone:
		assert_float(result).is_equal(0.0)


# --- Command structure ---

func test_command_exists_by_default() -> void:
	assert_object(input_comp.command).is_not_null()
	assert_bool(input_comp.command is InputCommand).is_true()


# --- Input actions ---

func test_update_input_creates_commands_on_just_pressed() -> void:
	Input.action_press("jump")
	input_comp.update_input(0.0)
	assert_bool(input_comp.get_command().has_command(CommandType.Type.JUMP)).is_true()
	Input.action_release("jump")
	
	Input.action_press("attack")
	input_comp.update_input(0.0)
	assert_bool(input_comp.get_command().has_command(CommandType.Type.ATTACK)).is_true()
	Input.action_release("attack")
	
	Input.action_press("dash")
	input_comp.update_input(0.0)
	assert_bool(input_comp.get_command().has_command(CommandType.Type.DASH)).is_true()
	Input.action_release("dash")
	
	Input.action_press("interact")
	input_comp.update_input(0.0)
	assert_bool(input_comp.get_command().has_command(CommandType.Type.INTERACT)).is_true()
	Input.action_release("interact")


func test_update_input_reads_move_axis() -> void:
	Input.action_press("move_right")
	input_comp.update_input(0.0)
	assert_float(input_comp.get_command().move_direction).is_equal_approx(1.0, 0.0001)
	Input.action_release("move_right")
	
	Input.action_press("move_left")
	input_comp.update_input(0.0)
	assert_float(input_comp.get_command().move_direction).is_equal_approx(-1.0, 0.0001)
	Input.action_release("move_left")


func test_is_action_held_forwards_to_input() -> void:
	Input.action_press("jump")
	assert_bool(input_comp.is_action_held("jump")).is_true()
	Input.action_release("jump")
	assert_bool(input_comp.is_action_held("jump")).is_false()
