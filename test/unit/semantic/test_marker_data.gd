## MarkerData, MarkerType and MarkerLayer unit tests.
## Covers: MarkerData defaults, field round-trip, MarkerType order lock,
## MarkerLayer grouping by type, unknown type returns empty, get_all_markers
## enum-type order, out-of-range types and duplicate append.
extends GdUnitTestSuite


# ── MarkerType ───────────────────────────────────────────────────────

func test_marker_type_keys_locked_order() -> void:
	assert_array(MarkerType.Value.keys()).is_equal(["ENEMY_SPAWN", "LOOT_SPAWN", "CHECKPOINT"])


# ── MarkerData resource ──────────────────────────────────────────────

func test_marker_data_defaults() -> void:
	var marker = MarkerData.new()

	assert_int(marker.type).is_equal(MarkerType.Value.ENEMY_SPAWN)
	assert_vector(marker.position).is_equal(Vector2i.ZERO)
	assert_str(marker.content_id).is_equal(&"")
	assert_str(marker.marker_id).is_equal(&"")


func test_marker_data_fields_round_trip() -> void:
	var marker = MarkerData.new()
	marker.type = MarkerType.Value.CHECKPOINT
	marker.position = Vector2i(5, 10)
	marker.content_id = &"enemy_01"
	marker.marker_id = &"spawn_a"

	assert_int(marker.type).is_equal(MarkerType.Value.CHECKPOINT)
	assert_vector(marker.position).is_equal(Vector2i(5, 10))
	assert_str(marker.content_id).is_equal(&"enemy_01")
	assert_str(marker.marker_id).is_equal(&"spawn_a")


# ── MarkerLayer grouping ─────────────────────────────────────────────

func test_marker_layer_groups_markers_by_type() -> void:
	var layer = MarkerLayer.new()
	var enemy = MarkerData.new()
	enemy.position = Vector2i(1, 1)
	var loot = MarkerData.new()
	loot.position = Vector2i(2, 2)

	layer.add_marker(MarkerType.Value.ENEMY_SPAWN, enemy)
	layer.add_marker(MarkerType.Value.LOOT_SPAWN, loot)

	assert_int(layer.get_markers(MarkerType.Value.ENEMY_SPAWN).size()).is_equal(1)
	assert_int(layer.get_markers(MarkerType.Value.LOOT_SPAWN).size()).is_equal(1)
	assert_vector(layer.get_markers(MarkerType.Value.ENEMY_SPAWN)[0].position).is_equal(Vector2i(1, 1))


func test_marker_layer_unknown_type_returns_empty() -> void:
	var layer = MarkerLayer.new()

	assert_int(layer.get_markers(MarkerType.Value.CHECKPOINT).size()).is_zero()


func test_marker_layer_all_markers_in_enum_order() -> void:
	var layer = MarkerLayer.new()
	var checkpoint = MarkerData.new()
	checkpoint.marker_id = &"checkpoint"
	var loot = MarkerData.new()
	loot.marker_id = &"loot"
	var enemy = MarkerData.new()
	enemy.marker_id = &"enemy"

	# Insert out of enum order to prove get_all_markers reorders by type.
	layer.add_marker(MarkerType.Value.CHECKPOINT, checkpoint)
	layer.add_marker(MarkerType.Value.LOOT_SPAWN, loot)
	layer.add_marker(MarkerType.Value.ENEMY_SPAWN, enemy)

	var all = layer.get_all_markers()
	assert_int(all.size()).is_equal(3)
	assert_str(all[0].marker_id).is_equal(&"enemy")
	assert_str(all[1].marker_id).is_equal(&"loot")
	assert_str(all[2].marker_id).is_equal(&"checkpoint")


@warning_ignore("int_as_enum_without_cast")
func test_marker_layer_all_markers_keeps_out_of_range_type() -> void:
	# An out-of-range serialized type must stay visible to validation instead of
	# being silently dropped by the enum-ordered flattening.
	var layer = MarkerLayer.new()
	var marker = MarkerData.new()
	marker.marker_id = &"out_of_range"

	layer.add_marker(42, marker)

	assert_int(layer.get_markers(42).size()).is_equal(1)
	var all = layer.get_all_markers()
	assert_int(all.size()).is_equal(1)
	assert_str(all[0].marker_id).is_equal(&"out_of_range")


func test_marker_layer_appends_duplicate_markers() -> void:
	var layer = MarkerLayer.new()
	var marker1 = MarkerData.new()
	marker1.position = Vector2i(1, 1)
	var marker2 = MarkerData.new()
	marker2.position = Vector2i(2, 2)

	layer.add_marker(MarkerType.Value.ENEMY_SPAWN, marker1)
	layer.add_marker(MarkerType.Value.ENEMY_SPAWN, marker2)

	var markers = layer.get_markers(MarkerType.Value.ENEMY_SPAWN)
	assert_int(markers.size()).is_equal(2)
