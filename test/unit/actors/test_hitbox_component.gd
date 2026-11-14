## HitboxComponent unit tests.
## Covers: _ready behaviour, _find_actor, _try_hit guard clauses, valid hit flow,
## activate/deactivate lifecycle, hit_targets deduplication, area_entered wiring.
extends GdUnitTestSuite

const ActorFixture = preload("res://test/fixtures/actor_fixture.gd")

var hitbox: HitboxComponent
var actor: Actor


# --- Setup helpers ---

func _make_attack() -> AttackData:
	return AttackData.new(10)


func _make_target_hurtbox() -> HurtboxComponent:
	return HurtboxComponent.new()


# --- _ready behaviour ---

func test_ready_sets_monitoring_to_false() -> void:
	var hb = auto_free(HitboxComponent.new())
	add_child(hb)
	assert_bool(hb.monitoring).is_false()


func test_ready_connects_area_entered_signal() -> void:
	var hb = auto_free(HitboxComponent.new())
	add_child(hb)
	# area_entered.connect is called in _ready; confirm via is_connected.
	# We create a dummy Area2D and check the callback exists by observing _try_hit
	# doesn't crash when the signal fires.
	assert_int(hb.get_signal_connection_list("area_entered").size()).is_equal(1)


func test_ready_finds_actor_and_stores_reference() -> void:
	actor = ActorFixture.build_actor()
	actor.name = "TestActor"

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	actor.add_child(hitbox)

	# Add actor to tree last, so _ready fires with all children present.
	add_child(actor)

	# After _ready, _actor should be set to the Actor parent.
	assert_object(hitbox._actor).is_not_null()
	assert_object(hitbox._actor).is_same(actor)


# --- _find_actor ---

func test_find_actor_finds_direct_parent() -> void:
	actor = ActorFixture.build_actor()
	actor.name = "TestActor"

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	actor.add_child(hitbox)

	add_child(actor)
	hitbox._actor = hitbox._find_actor(hitbox)

	assert_object(hitbox._actor).is_same(actor)


func test_find_actor_finds_nested_actor_grandparent() -> void:
	actor = ActorFixture.build_actor()
	actor.name = "TestActor"

	var intermediate := Node2D.new()
	intermediate.name = "Intermediate"
	actor.add_child(intermediate)

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	intermediate.add_child(hitbox)

	add_child(actor)
	hitbox._actor = hitbox._find_actor(hitbox)

	assert_object(hitbox._actor).is_same(actor)


func test_find_actor_returns_null_when_no_actor_ancestor() -> void:
	var root := Node2D.new()
	root.name = "Root"
	add_child(root)

	var child := Node2D.new()
	child.name = "Child"
	root.add_child(child)

	hitbox = auto_free(HitboxComponent.new())
	hitbox.name = "HitboxComponent"
	child.add_child(hitbox)

	var found := hitbox._find_actor(hitbox)
	assert_object(found).is_null()


# --- _try_hit guard: inactive ---

func test_try_hit_when_inactive_does_nothing() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.active = false

	var hurtbox_target: HurtboxComponent = auto_free(HurtboxComponent.new())
	hitbox._try_hit(hurtbox_target)

	assert_bool(hitbox.hit_targets.has(hurtbox_target)).is_false()


# --- _try_hit guard: not a hurtbox ---

func test_try_hit_ignores_non_hurtbox_area() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.active = true

	var plain_area: Area2D = auto_free(Area2D.new())
	hitbox._try_hit(plain_area)

	assert_int(hitbox.hit_targets.size()).is_zero()


# --- _try_hit guard: same actor ---

func test_try_hit_ignores_hurtbox_from_same_actor() -> void:
	actor = ActorFixture.build_actor()
	actor.name = "TestActor"

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	actor.add_child(hitbox)

	add_child(actor)
	hitbox._actor = actor
	hitbox.active = true

	hitbox._try_hit(actor.hurtbox)

	assert_int(hitbox.hit_targets.size()).is_zero()


# --- _try_hit guard: already hit ---

func test_try_hit_ignores_already_hit_target() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.active = true

	var target: HurtboxComponent = auto_free(HurtboxComponent.new())
	hitbox.hit_targets[target] = true

	hitbox._try_hit(target)

	# hit_targets should still only have one entry
	assert_int(hitbox.hit_targets.size()).is_equal(1)


# --- Valid hit: calls receive_hit and emits hit_target ---

func test_try_hit_calls_receive_hit_on_valid_target() -> void:
	hitbox = HitboxComponent.new()
	add_child(hitbox)
	# The target has no actor ancestor, so give the hitbox a different actor to
	# avoid the same-actor guard matching (null == null).
	hitbox._actor = auto_free(Actor.new())

	var target: HurtboxComponent = HurtboxComponent.new()
	target.name = "TargetHurtbox"
	add_child(target)
	monitor_signals(target, false)

	var attack = _make_attack()
	hitbox.active = true
	hitbox._attack_data = attack
	hitbox._try_hit(target)

	await assert_signal(target).is_emitted("hit_received", attack)


func test_try_hit_emits_hit_target_signal() -> void:
	hitbox = HitboxComponent.new()
	add_child(hitbox)
	# The target has no actor ancestor, so give the hitbox a different actor to
	# avoid the same-actor guard matching (null == null).
	hitbox._actor = auto_free(Actor.new())
	monitor_signals(hitbox, false)

	var target: HurtboxComponent = HurtboxComponent.new()
	target.name = "TargetHurtbox"
	add_child(target)

	var attack = _make_attack()
	hitbox.active = true
	hitbox._attack_data = attack
	hitbox._try_hit(target)

	await assert_signal(hitbox).is_emitted("hit_target", target)


func test_try_hit_adds_target_to_hit_targets() -> void:
	hitbox = HitboxComponent.new()
	add_child(hitbox)
	# The target has no actor ancestor, so give the hitbox a different actor to
	# avoid the same-actor guard matching (null == null).
	hitbox._actor = auto_free(Actor.new())

	var target: HurtboxComponent = HurtboxComponent.new()
	target.name = "TargetHurtbox"
	add_child(target)

	var attack = _make_attack()
	hitbox.active = true
	hitbox._attack_data = attack
	hitbox._try_hit(target)

	assert_bool(hitbox.hit_targets.has(target)).is_true()


# --- activate ---

func test_activate_sets_active_true() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.activate(_make_attack())
	assert_bool(hitbox.active).is_true()


func test_activate_sets_monitoring_true() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.activate(_make_attack())
	assert_bool(hitbox.monitoring).is_true()


func test_activate_clears_hit_targets() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.hit_targets["fake"] = true
	hitbox.activate(_make_attack())
	assert_int(hitbox.hit_targets.size()).is_zero()


func test_activate_stores_attack_data() -> void:
	hitbox = auto_free(HitboxComponent.new())
	var attack = _make_attack()
	hitbox.activate(attack)
	assert_object(hitbox._attack_data).is_same(attack)


# --- deactivate ---

func test_deactivate_sets_active_false() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.activate(_make_attack())
	hitbox.deactivate()
	assert_bool(hitbox.active).is_false()


func test_deactivate_sets_monitoring_false() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.activate(_make_attack())
	hitbox.deactivate()
	assert_bool(hitbox.monitoring).is_false()


# --- area_entered integration ---

func test_area_entered_triggers_try_hit_when_active() -> void:
	actor = ActorFixture.build_actor()
	actor.name = "TestActor"

	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	actor.add_child(hitbox)

	add_child(actor)
	monitor_signals(hitbox, false)

	var attack = _make_attack()
	hitbox.activate(attack)
	assert_bool(hitbox.active).is_true()
	assert_bool(hitbox.monitoring).is_true()

	# Simulate area_entered by calling the connected callback directly.
	# The target has no actor ancestor, so it is not considered the same actor
	# as the hitbox.
	var target: HurtboxComponent = HurtboxComponent.new()
	target.name = "TargetHurtbox"
	add_child(target)
	monitor_signals(target, false)
	hitbox._on_area_entered(target)

	await assert_signal(target).is_emitted("hit_received", attack)
	await assert_signal(hitbox).is_emitted("hit_target", target)


func test_area_entered_is_noop_when_inactive() -> void:
	hitbox = auto_free(HitboxComponent.new())
	hitbox.active = false

	var target: HurtboxComponent = auto_free(HurtboxComponent.new())
	hitbox._on_area_entered(target)

	assert_int(hitbox.hit_targets.size()).is_zero()
