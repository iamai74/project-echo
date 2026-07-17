extends Node


func _ready() -> void:
	_setup_keyboard()
	_setup_gamepad()


func _setup_keyboard() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_mouse_button("attack", MOUSE_BUTTON_LEFT)
	_add_keys("dash", [KEY_SHIFT])
	_add_keys("interact", [KEY_E])


func _setup_gamepad() -> void:
	_add_joypad_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joypad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joypad_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joypad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joypad_button("jump", JOY_BUTTON_A)
	_add_joypad_button("attack", JOY_BUTTON_X)
	_add_joypad_button("dash", JOY_BUTTON_B)
	_add_joypad_button("interact", JOY_BUTTON_Y)


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)


func _has_matching_event(action_name: String, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action_name):
		if existing.is_match(event):
			return true
	return false


func _add_event(action_name: String, event: InputEvent) -> void:
	_ensure_action(action_name)
	if _has_matching_event(action_name, event):
		return
	InputMap.action_add_event(action_name, event)


func _add_keys(action_name: String, keys: Array[Key]) -> void:
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		_add_event(action_name, event)


func _add_mouse_button(action_name: String, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add_event(action_name, event)


func _add_joypad_button(action_name: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_add_event(action_name, event)


func _add_joypad_axis(action_name: String, axis: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	_add_event(action_name, event)
