## InputSetup autoload tests.
## Covers: expected action registration, idempotency and keyboard/gamepad
## event registration.
extends GdUnitTestSuite


const InputSetupScript = preload("res://scripts/core/input/input_setup.gd")

const EXPECTED_ACTIONS := [
	"move_left",
	"move_right",
	"jump",
	"attack",
	"dash",
	"interact",
]


var setup: Node


func before_test() -> void:
	setup = auto_free(InputSetupScript.new())


func _register_all() -> void:
	setup._setup_keyboard()
	setup._setup_gamepad()


func test_registers_expected_actions() -> void:
	_register_all()

	for action in EXPECTED_ACTIONS:
		assert_bool(InputMap.has_action(action)).is_true()


func test_does_not_duplicate_actions_when_called_twice() -> void:
	_register_all()

	var counts := {}
	for action in EXPECTED_ACTIONS:
		counts[action] = InputMap.action_get_events(action).size()

	_register_all()

	for action in EXPECTED_ACTIONS:
		assert_int(InputMap.action_get_events(action).size()).is_equal(counts[action])


func test_registers_keyboard_and_gamepad_events() -> void:
	_register_all()

	var has_key := false
	var has_joypad_button := false
	var has_joypad_axis := false
	var has_mouse_button := false

	for action in EXPECTED_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_key = true
			elif event is InputEventJoypadButton:
				has_joypad_button = true
			elif event is InputEventJoypadMotion:
				has_joypad_axis = true
			elif event is InputEventMouseButton:
				has_mouse_button = true

	assert_bool(has_key).is_true()
	assert_bool(has_joypad_button).is_true()
	assert_bool(has_joypad_axis).is_true()
	assert_bool(has_mouse_button).is_true()


func test_jump_registers_keyboard_and_gamepad_button() -> void:
	_register_all()

	var has_key := false
	var has_button := false
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey:
			has_key = true
		elif event is InputEventJoypadButton:
			has_button = true

	assert_bool(has_key).is_true()
	assert_bool(has_button).is_true()
