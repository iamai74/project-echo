## Walker unit tests.
## Covers: patrol transition logic based on movement and floor contact.
extends GdUnitTestSuite

const Fixture = preload("res://scripts/test/fixtures/actor_state_fixture.gd")

var walker

func before_test() -> void:
	walker = auto_free(Fixture.build_walker())
	Fixture.add_enemy_states(walker)
	Fixture.start_walker(walker)


func test_walker_starts_in_idle() -> void:
	assert_str(walker.state_machine.current_state.name).is_equal("Idle")


func test_walker_transitions_to_patrol_on_movement_on_floor() -> void:
	walker.grounded = true
	walker.global_position = Vector2(10.0, 0.0)

	walker._try_start_patrol(Vector2.ZERO)

	assert_str(walker.state_machine.current_state.name).is_equal("Patrol")


func test_walker_does_not_transition_to_patrol_if_not_moving() -> void:
	walker.grounded = true
	walker.global_position = Vector2.ZERO

	walker._try_start_patrol(Vector2.ZERO)

	assert_str(walker.state_machine.current_state.name).is_equal("Idle")


func test_walker_does_not_transition_to_patrol_when_airborne() -> void:
	walker.grounded = false
	walker.global_position = Vector2(10.0, 0.0)

	walker._try_start_patrol(Vector2.ZERO)

	assert_str(walker.state_machine.current_state.name).is_equal("Idle")


func test_walker_does_not_transition_to_patrol_if_already_in_combat_state() -> void:
	walker.grounded = true
	walker.global_position = Vector2(10.0, 0.0)
	walker.state_machine.change_state("Hurt")

	walker._try_start_patrol(Vector2.ZERO)

	assert_str(walker.state_machine.current_state.name).is_equal("Hurt")
