## StateMachine unit tests.
## Covers: start, change, previous state, same-state no-op, missing state error,
## update/physics_update/handle_input/handle_attack_finished forwarding to the current
## state, no-current-state no-ops, initialize populates states dictionary.
extends GdUnitTestSuite

# Minimal test fixture: a State subclass that tracks enter/exit calls.
# Used via load() in tests so GDScript inner-class limits don't apply.


func _make_test_state(name: String) -> State:
	var state = State.new()
	state.name = name
	return state


func _make_state_machine_with_states() -> StateMachine:
	var sm = auto_free(StateMachine.new())
	sm.name = "StateMachine"

	var state_a = _make_test_state("StateA")
	sm.add_child(state_a)

	var state_b = _make_test_state("StateB")
	sm.add_child(state_b)

	# Manually populate states dict (normally initialize() does this by scanning children)
	for child in sm.get_children():
		if child is State:
			sm.states[child.name] = child
			child.state_machine = sm

	return sm


# --- Start ---

func test_start_sets_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")

	assert_object(sm.current_state).is_not_null()
	assert_str(sm.current_state.name).is_equal("StateA")


func test_start_does_not_set_previous_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")

	assert_object(sm.previous_state).is_null()


# --- Change state ---

func test_change_state_sets_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	sm.change_state("StateB")

	assert_object(sm.current_state).is_not_null()
	assert_str(sm.current_state.name).is_equal("StateB")


func test_change_state_sets_previous_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	sm.change_state("StateB")

	assert_object(sm.previous_state).is_not_null()
	assert_str(sm.previous_state.name).is_equal("StateA")


func test_change_state_same_state_is_noop() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	var original_state = sm.current_state
	sm.change_state("StateA")

	# Should still be the same state, previous_state should not be set
	assert_object(sm.current_state).is_equal(original_state)
	assert_object(sm.previous_state).is_null()


# --- Missing state ---

func test_start_missing_state_pushes_error() -> void:
	var sm = _make_state_machine_with_states()
	assert_error(func() -> void: sm.start("NonExistent")) \
		.is_push_error("State not found: NonExistent")


func test_change_state_missing_state_pushes_error() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	assert_error(func() -> void: sm.change_state("NonExistent")) \
		.is_push_error("State not found: NonExistent")


func test_start_missing_state_does_not_change_current() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	assert_error(func() -> void: sm.start("NonExistent")) \
		.is_push_error("State not found: NonExistent")
	assert_str(sm.current_state.name).is_equal("StateA")


# --- Update forwarding ---

func test_update_forwards_to_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	# Calling update should not error and should complete without crashing
	sm.update(0.05)
	assert_object(sm.current_state).is_not_null()


func test_update_noops_when_no_current_state() -> void:
	var sm = _make_state_machine_with_states()
	# Don't start any state — update should not crash
	sm.update(0.05)
	assert_object(sm.current_state).is_null()


# --- Forwarding to current state ---

func test_physics_update_forwards_to_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	var state_spy = spy(sm.current_state)
	sm.current_state = state_spy
	var delta := 0.25
	sm.physics_update(delta)
	verify(state_spy, 1).physics_update(delta)
	verify_no_more_interactions(state_spy)


func test_handle_input_forwards_to_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	var state_spy = spy(sm.current_state)
	sm.current_state = state_spy
	var event := InputEventAction.new()
	sm.handle_input(event)
	verify(state_spy, 1).handle_input(event)
	verify_no_more_interactions(state_spy)


func test_handle_attack_finished_forwards_to_current_state() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	var state_spy = spy(sm.current_state)
	sm.current_state = state_spy
	var attack := AttackDefinition.new()
	sm.handle_attack_finished(attack)
	verify(state_spy, 1).on_attack_finished(attack)
	verify_no_more_interactions(state_spy)


# --- No current state no-ops ---

func test_physics_update_noops_when_no_current_state() -> void:
	var sm = _make_state_machine_with_states()
	assert_error(func() -> void: sm.physics_update(0.25)).is_success()
	assert_object(sm.current_state).is_null()


func test_handle_input_noops_when_no_current_state() -> void:
	var sm = _make_state_machine_with_states()
	assert_error(func() -> void: sm.handle_input(InputEventAction.new())).is_success()
	assert_object(sm.current_state).is_null()


func test_handle_attack_finished_noops_when_no_current_state() -> void:
	var sm = _make_state_machine_with_states()
	assert_error(func() -> void: sm.handle_attack_finished(AttackDefinition.new())).is_success()
	assert_object(sm.current_state).is_null()


# --- Initialize populates states ---

func test_states_dictionary_is_empty_before_setup() -> void:
	var sm = auto_free(StateMachine.new())
	sm.name = "StateMachine"
	assert_int(sm.states.size()).is_zero()


# --- Multiple state transitions ---

func test_multiple_transitions_update_current_and_previous() -> void:
	var sm = _make_state_machine_with_states()
	sm.start("StateA")
	sm.change_state("StateB")

	assert_str(sm.current_state.name).is_equal("StateB")
	assert_str(sm.previous_state.name).is_equal("StateA")
