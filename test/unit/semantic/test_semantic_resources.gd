## Semantic resource unit tests.
## Covers: ConnectionData defaults and fields, BackgroundCell position,
## SemanticVolume default properties.
extends GdUnitTestSuite


# ── ConnectionData ───────────────────────────────────────────────────

func test_connection_data_defaults() -> void:
	var data = ConnectionData.new()

	assert_str(data.id).is_equal(&"")
	assert_int(data.side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(data.position).is_equal(Vector2i.ZERO)
	assert_vector(data.size).is_equal(Vector2i.ZERO)


func test_connection_data_fields_round_trip() -> void:
	var data = ConnectionData.new()
	data.id = &"test_connection"
	data.side = ConnectionSide.Value.BOTTOM
	data.position = Vector2i(5, 10)
	data.size = Vector2i(3, 2)

	assert_str(data.id).is_equal(&"test_connection")
	assert_int(data.side).is_equal(ConnectionSide.Value.BOTTOM)
	assert_vector(data.position).is_equal(Vector2i(5, 10))
	assert_vector(data.size).is_equal(Vector2i(3, 2))


func test_connection_side_keys_locked_order() -> void:
	assert_array(ConnectionSide.Value.keys()).is_equal(["TOP", "BOTTOM", "RIGHT", "LEFT"])


# ── BackgroundCell ───────────────────────────────────────────────────

func test_background_cell_stores_position() -> void:
	var cell = BackgroundCell.new()
	cell.position = Vector2i(4, 7)
	
	assert_vector(cell.position).is_equal(Vector2i(4, 7))


# ── SemanticVolume ───────────────────────────────────────────────────

func test_semantic_volume_defaults_safe() -> void:
	var volume = SemanticVolume.new()
	
	assert_int(volume.polygon.size()).is_zero()
	assert_int(volume.properties.size()).is_zero()
