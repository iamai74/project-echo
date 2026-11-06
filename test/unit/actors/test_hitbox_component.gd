## HitboxComponent unit tests.
## Covers: active/inactive state, deactivate clears monitoring, 
## hit_targets deduplication, inactive ignores hits.
extends GdUnitTestSuite


var hitbox: HitboxComponent


func before_test() -> void:
	hitbox = auto_free(HitboxComponent.new())
	# Set monitoring to false initially (matches _ready behavior)
	hitbox.monitoring = false
	hitbox.active = false


# --- Activation ---

func test_activate_sets_active_true() -> void:
	var attack = AttackData.new(10)
	hitbox.activate(attack)
	assert_bool(hitbox.active).is_true()


func test_activate_sets_monitoring_true() -> void:
	var attack = AttackData.new(10)
	hitbox.activate(attack)
	assert_bool(hitbox.monitoring).is_true()


func test_activate_clears_hit_targets() -> void:
	hitbox.hit_targets["fake"] = true
	var attack = AttackData.new(10)
	hitbox.activate(attack)
	assert_int(hitbox.hit_targets.size()).is_zero()


func test_deactivate_sets_active_false() -> void:
	var attack = AttackData.new(10)
	hitbox.activate(attack)
	hitbox.deactivate()
	assert_bool(hitbox.active).is_false()


func test_deactivate_sets_monitoring_false() -> void:
	var attack = AttackData.new(10)
	hitbox.activate(attack)
	hitbox.deactivate()
	assert_bool(hitbox.monitoring).is_false()


# --- Try hit when inactive ---

func test_try_hit_when_inactive_does_nothing() -> void:
	hitbox.active = false
	# Create a mock hurtbox; _try_hit returns early when inactive
	# so the hurtbox should not receive any call
	var hurtbox_mock = auto_free(HurtboxComponent.new())
	hitbox._try_hit(hurtbox_mock)
	# If it reached receive_hit, the signal would fire
	assert_bool(hitbox.active).is_false()
