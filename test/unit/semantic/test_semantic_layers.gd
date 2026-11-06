## Semantic layer unit tests.
## Covers: MarkerLayer stores markers per type, VolumeLayer stores volumes per type,
## unknown types return empty arrays, duplicate markers/volumes are appended.
extends GdUnitTestSuite


# ── MarkerLayer ──────────────────────────────────────────────────────

func test_marker_layer_stores_markers_per_type() -> void:
	var layer = MarkerLayer.new()
	var marker = SemanticMarker.new()
	marker.position = Vector2i(1, 1)
	
	layer.add_marker(MarkerLayer.MarkerType.ENEMY_SPAWN, marker)
	
	var markers = layer.get_markers(MarkerLayer.MarkerType.ENEMY_SPAWN)
	assert_int(markers.size()).is_equal(1)
	assert_vector(markers[0].position).is_equal(Vector2i(1, 1))


func test_marker_layer_unknown_type_returns_empty() -> void:
	var layer = MarkerLayer.new()
	
	var markers = layer.get_markers(MarkerLayer.MarkerType.ENEMY_SPAWN)
	
	assert_int(markers.size()).is_zero()


func test_marker_layer_appends_duplicate_markers() -> void:
	var layer = MarkerLayer.new()
	var marker1 = SemanticMarker.new()
	marker1.position = Vector2i(1, 1)
	var marker2 = SemanticMarker.new()
	marker2.position = Vector2i(2, 2)
	
	layer.add_marker(MarkerLayer.MarkerType.ENEMY_SPAWN, marker1)
	layer.add_marker(MarkerLayer.MarkerType.ENEMY_SPAWN, marker2)
	
	var markers = layer.get_markers(MarkerLayer.MarkerType.ENEMY_SPAWN)
	assert_int(markers.size()).is_equal(2)


# ── VolumeLayer ──────────────────────────────────────────────────────

func test_volume_layer_stores_volumes_per_type() -> void:
	var layer = VolumeLayer.new()
	var volume = SemanticVolume.new()
	volume.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	
	layer.add_item(VolumeLayer.VolumeType.MUSIC_ZONE, volume)
	
	var items = layer.get_items(VolumeLayer.VolumeType.MUSIC_ZONE)
	assert_int(items.size()).is_equal(1)


func test_volume_layer_unknown_type_returns_empty() -> void:
	var layer = VolumeLayer.new()
	
	var items = layer.get_items(VolumeLayer.VolumeType.MUSIC_ZONE)
	
	assert_int(items.size()).is_zero()


func test_volume_layer_appends_duplicate_volumes() -> void:
	var layer = VolumeLayer.new()
	var volume1 = SemanticVolume.new()
	volume1.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var volume2 = SemanticVolume.new()
	volume2.polygon = PackedVector2Array([Vector2(2, 2), Vector2(3, 2), Vector2(3, 3), Vector2(2, 3)])
	
	layer.add_item(VolumeLayer.VolumeType.MUSIC_ZONE, volume1)
	layer.add_item(VolumeLayer.VolumeType.MUSIC_ZONE, volume2)
	
	var items = layer.get_items(VolumeLayer.VolumeType.MUSIC_ZONE)
	assert_int(items.size()).is_equal(2)
