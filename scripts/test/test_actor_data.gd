## ActorData resource tests.
## Covers: gameplay defaults and independent overrides.
extends GdUnitTestSuite


func test_default_values_match_gameplay_contract() -> void:
	var data := ActorData.new()

	assert_int(data.max_health).is_equal(5)
	assert_float(data.move_speed).is_equal(220.0)
	assert_float(data.jump_velocity).is_equal(-420.0)
	assert_float(data.gravity).is_equal(1200.0)
	assert_float(data.coyote_time).is_equal(0.1)
	assert_int(data.max_jumps).is_equal(2)
	assert_float(data.jump_hold_force).is_equal(0.3)


func test_exported_values_can_be_overridden_independently() -> void:
	var data := ActorData.new()

	data.max_health = 20
	data.move_speed = 300.0
	data.max_jumps = 1

	assert_int(data.max_health).is_equal(20)
	assert_float(data.move_speed).is_equal(300.0)
	assert_int(data.max_jumps).is_equal(1)
	assert_float(data.jump_velocity).is_equal(-420.0)
	assert_float(data.gravity).is_equal(1200.0)
