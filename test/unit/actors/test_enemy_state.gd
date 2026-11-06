## EnemyState unit tests.
## Covers: movement-input contract, death transition and combat-state
## suppression of global transitions.
extends GdUnitTestSuite


const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")


var enemy


func before_test() -> void:
	enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy)


func _state(state_name: String) -> EnemyState:
	return enemy.state_machine.states[state_name] as EnemyState


func test_has_movement_input_matches_enemy_contract() -> void:
	assert_bool(_state("Idle").has_movement_input()).is_false()


func test_global_death_transition_runs_before_other_transitions() -> void:
	var idle := _state("Idle")
	enemy.health.current_health = 0

	idle.physics_update(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Dead")
	assert_bool(enemy.died).is_true()


func test_combat_states_ignore_non_death_global_transitions() -> void:
	var custom = auto_free(Fixture.build_enemy())
	Fixture.add_state(custom.state_machine, "Idle", EnemyIdleState.new())
	Fixture.add_state(custom.state_machine, "Attack", EnemyState.new())
	Fixture.add_state(custom.state_machine, "Hurt", EnemyState.new())
	Fixture.start_enemy(custom)

	custom.state_machine.change_state("Attack")
	var attack_state: EnemyState = custom.state_machine.states["Attack"]
	attack_state.physics_update(0.0)
	assert_str(custom.state_machine.current_state.name).is_equal("Attack")

	custom.state_machine.change_state("Hurt")
	var hurt_state: EnemyState = custom.state_machine.states["Hurt"]
	hurt_state.physics_update(0.0)
	assert_str(custom.state_machine.current_state.name).is_equal("Hurt")
