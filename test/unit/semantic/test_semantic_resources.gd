## Semantic resource unit tests.
## Covers: ConnectionData defaults and fields, BackgroundCell position,
## SemanticMarker and SemanticVolume default properties.
extends GdUnitTestSuite


# ── ConnectionData ───────────────────────────────────────────────────

func test_connection_data_defaults() -> void:
	var data = ConnectionData.new()
	
	assert_str(data.id).is_equal(&"")
	assert_int(data.side).is_equal(ConnectionData.Side.TOP)
	assert_vector(data.position).is_equal(Vector2i.ZERO)
	assert_vector(data.size).is_equal(Vector2i.ZERO)


func test_connection_data_fields_round_trip() -> void:
	var data = ConnectionData.new()
	data.id = &"test_connection"
	data.side = ConnectionData.Side.BOTTOM
	data.position = Vector2i(5, 10)
	data.size = Vector2i(3, 2)
	
	assert_str(data.id).is_equal(&"test_connection")
	assert_int(data.side).is_equal(ConnectionData.Side.BOTTOM)
	assert_vector(data.position).is_equal(Vector2i(5, 10))
	assert_vector(data.size).is_equal(Vector2i(3, 2))


# ── BackgroundCell ───────────────────────────────────────────────────

func test_background_cell_stores_position() -> void:
	var cell = BackgroundCell.new()
	cell.position = Vector2i(4, 7)
	
	assert_vector(cell.position).is_equal(Vector2i(4, 7))


# ── SemanticMarker ───────────────────────────────────────────────────

func test_semantic_marker_defaults_safe() -> void:
	var marker = SemanticMarker.new()
	
	assert_vector(marker.position).is_equal(Vector2i.ZERO)
	assert_int(marker.properties.size()).is_zero()


# ── SemanticVolume ───────────────────────────────────────────────────

func test_semantic_volume_defaults_safe() -> void:
	var volume = SemanticVolume.new()
	
	assert_int(volume.polygon.size()).is_zero()
	assert_int(volume.properties.size()).is_zero()
