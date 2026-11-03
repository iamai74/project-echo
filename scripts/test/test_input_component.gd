## InputComponent unit tests.
## Covers: deadzone application, command creation structure, input enabled/disabled.
extends GdUnitTestSuite


var input_comp: InputComponent


func before_test() -> void:
	input_comp = auto_free(InputComponent.new())
	input_comp.stick_deadzone = 0.2


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


# --- Command structure ---

func test_command_exists_by_default() -> void:
	assert_object(input_comp.command).is_not_null()
	assert_bool(input_comp.command is InputCommand).is_true()


# --- Input enabled/disabled ---

func test_set_input_enabled_enables_processing() -> void:
	input_comp.set_input_enabled(false)
	assert_int(input_comp.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

	input_comp.set_input_enabled(true)
	assert_int(input_comp.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
