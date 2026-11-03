## HurtboxComponent unit tests.
## Covers: hit signal, invulnerable state, blocked signal, can_receive_hit.
extends GdUnitTestSuite


var hurtbox: HurtboxComponent


func before_test() -> void:
	hurtbox = auto_free(HurtboxComponent.new())


# --- Initial state ---

func test_initially_can_receive_hit() -> void:
	assert_bool(hurtbox.can_receive_hit()).is_true()


# --- Invulnerability ---

func test_set_invulnerable_blocks_hits() -> void:
	hurtbox.set_invulnerable(true)
	assert_bool(hurtbox.can_receive_hit()).is_false()


func test_set_invulnerable_false_restores() -> void:
	hurtbox.set_invulnerable(true)
	hurtbox.set_invulnerable(false)
	assert_bool(hurtbox.can_receive_hit()).is_true()


# --- Hit signal ---

func test_receive_hit_emits_hit_received_signal() -> void:
	monitor_signals(hurtbox, false)
	var attack = AttackData.new(10)
	hurtbox.receive_hit(attack)
	await assert_signal(hurtbox).is_emitted("hit_received", attack)


# --- Blocked signal ---

func test_receive_hit_while_invulnerable_emits_blocked() -> void:
	monitor_signals(hurtbox, false)
	hurtbox.set_invulnerable(true)
	var attack = AttackData.new(10)
	hurtbox.receive_hit(attack)
	await assert_signal(hurtbox).is_emitted("damage_blocked")


func test_receive_hit_while_invulnerable_does_not_emit_hit_received() -> void:
	monitor_signals(hurtbox, false)
	hurtbox.set_invulnerable(true)
	var attack = AttackData.new(10)
	hurtbox.receive_hit(attack)
	# hit_received should NOT be emitted when invulnerable
	# We can check by ensuring the signal was not emitted with the attack argument
	await assert_signal(hurtbox).is_not_emitted("hit_received")
