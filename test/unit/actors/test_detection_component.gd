## DetectionComponent unit tests.
## Covers: area filtering, target acquisition/loss signals, target position, and
## _ready() signal wiring (area_entered/area_exited connections and driven detection).
extends GdUnitTestSuite


var detection: DetectionComponent


func before_test() -> void:
	detection = auto_free(DetectionComponent.new())


func _make_player(position: Vector2) -> Array:
	var player := Player.new()
	player.global_position = position
	var hurtbox := HurtboxComponent.new()
	player.add_child(hurtbox)
	auto_free(player)
	return [player, hurtbox]


func _make_non_player_hurtbox() -> HurtboxComponent:
	var actor := Actor.new()
	var hurtbox := HurtboxComponent.new()
	actor.add_child(hurtbox)
	auto_free(actor)
	return hurtbox


func test_non_hurtbox_areas_are_ignored() -> void:
	var area: Area2D = auto_free(Area2D.new())

	detection._on_area_entered(area)

	assert_vector(detection.get_target_position()).is_equal(Vector2.INF)


func test_hurtboxes_owned_by_non_player_actors_are_ignored() -> void:
	var hurtbox := _make_non_player_hurtbox()

	detection._on_area_entered(hurtbox)

	assert_vector(detection.get_target_position()).is_equal(Vector2.INF)


func test_player_hurtbox_sets_target_and_emits_once() -> void:
	var detected: Array[Player] = []
	detection.player_detected.connect(func(player: Player) -> void: detected.append(player))
	var player_parts := _make_player(Vector2(10.0, 20.0))
	var hurtbox: HurtboxComponent = player_parts[1]

	detection._on_area_entered(hurtbox)
	detection._on_area_entered(hurtbox)

	assert_int(detected.size()).is_equal(1)
	assert_vector(detection.get_target_position()).is_equal(Vector2(10.0, 20.0))


func test_exiting_detected_player_clears_target_and_emits_lost() -> void:
	var lost_count: Array[int] = [0]
	detection.player_lost.connect(func() -> void: lost_count[0] += 1)
	var player_parts := _make_player(Vector2(10.0, 20.0))
	var hurtbox: HurtboxComponent = player_parts[1]

	detection._on_area_entered(hurtbox)
	detection._on_area_exited(hurtbox)

	assert_vector(detection.get_target_position()).is_equal(Vector2.INF)
	assert_int(lost_count[0]).is_equal(1)


func test_exiting_unrelated_hurtbox_does_not_clear_target() -> void:
	var player_parts := _make_player(Vector2(10.0, 20.0))
	var player_hurtbox: HurtboxComponent = player_parts[1]
	var other_hurtbox := _make_non_player_hurtbox()

	detection._on_area_entered(player_hurtbox)
	detection._on_area_exited(other_hurtbox)

	assert_vector(detection.get_target_position()).is_equal(Vector2(10.0, 20.0))


func test_get_target_position_returns_inf_without_target() -> void:
	assert_vector(detection.get_target_position()).is_equal(Vector2.INF)


func test_ready_connects_area_signals() -> void:
	add_child(detection)

	assert_int(detection.get_signal_connection_list("area_entered").size()).is_equal(1)
	assert_int(detection.get_signal_connection_list("area_exited").size()).is_equal(1)
	assert_bool(detection.area_entered.is_connected(detection._on_area_entered)).is_true()
	assert_bool(detection.area_exited.is_connected(detection._on_area_exited)).is_true()


func test_ready_wired_detection_tracks_player() -> void:
	add_child(detection)

	var detected: Array[Player] = []
	var lost_count: Array[int] = [0]
	detection.player_detected.connect(func(player: Player) -> void: detected.append(player))
	detection.player_lost.connect(func() -> void: lost_count[0] += 1)

	var player_parts := _make_player(Vector2(10.0, 20.0))
	var hurtbox: HurtboxComponent = player_parts[1]

	detection.area_entered.emit(hurtbox)
	detection.area_entered.emit(hurtbox)

	assert_int(detected.size()).is_equal(1)
	assert_vector(detection.get_target_position()).is_equal(Vector2(10.0, 20.0))

	detection.area_exited.emit(hurtbox)

	assert_int(lost_count[0]).is_equal(1)
	assert_vector(detection.get_target_position()).is_equal(Vector2.INF)
