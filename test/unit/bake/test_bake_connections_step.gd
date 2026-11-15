## BakeConnectionsStep unit tests.
## Covers: step metadata, connection data generation from enabled connection
## brushes, disabled-brush skipping, explicit/empty/duplicate ID preservation,
## deterministic sorting, overlap preservation, and fatal issues for
## non-connection brushes and missing inputs.
extends GdUnitTestSuite


const TILE_SIZE := 32


# A brush that reports the CONNECTION_POINT type but is not a
# ConnectionPointBrush, used to prove the step records a fatal issue when a
# cast to ConnectionPointBrush fails.
class MockConnectionLikeBrush:
	extends SemanticBrush


	func get_brush_type() -> SemanticBrush.BrushType:
		return SemanticBrush.BrushType.CONNECTION_POINT


# --- Helpers ---


func _make_context() -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.brushes = BrushCollection.new()
	return context


func _make_connection_brush(
	grid_position: Vector2i,
	side: ConnectionSide.Value,
	connection_id: StringName,
	size: Vector2i = Vector2i.ONE,
	enabled: bool = true
) -> ConnectionPointBrush:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2(grid_position.x * TILE_SIZE, grid_position.y * TILE_SIZE)
	brush.side = side
	brush.connection_id = connection_id
	brush.size = size
	brush.enabled = enabled
	return brush


func _run(context: RoomBakeContext) -> Array[ConnectionData]:
	BakeConnectionsStep.new().run(context)
	return context.semantic_data.connections


# --- Step metadata ---


func test_get_id_returns_bake_connections() -> void:
	var step := BakeConnectionsStep.new()
	assert_str(step.get_id()).is_equal(&"bake_connections")


func test_get_display_name_returns_string() -> void:
	var step := BakeConnectionsStep.new()
	assert_str(step.get_display_name()).is_not_empty()


# --- Connection data generation ---


func test_enabled_connection_brush_produces_connection_with_copied_fields() -> void:
	var context := _make_context()
	var brush := _make_connection_brush(
		Vector2i(2, 3),
		ConnectionSide.Value.TOP,
		&"main_exit",
		Vector2i(3, 1)
	)
	context.brushes.add_brush(brush)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(1)

	var connection: ConnectionData = connections[0]
	assert_str(connection.id).is_equal(&"main_exit")
	assert_int(connection.side).is_equal(ConnectionSide.Value.TOP)
	assert_vector(connection.position).is_equal(Vector2i(2, 3))
	assert_vector(connection.size).is_equal(Vector2i(3, 1))


func test_disabled_connection_brush_produces_no_connection() -> void:
	var context := _make_context()
	var brush := _make_connection_brush(
		Vector2i(1, 1),
		ConnectionSide.Value.LEFT,
		&"unused_exit",
		Vector2i(1, 2),
		false
	)
	context.brushes.add_brush(brush)

	var connections := _run(context)

	assert_int(connections.size()).is_zero()


# --- ID preservation ---


func test_explicit_id_is_preserved() -> void:
	var context := _make_context()
	var brush := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.BOTTOM,
		&"boss_door"
	)
	context.brushes.add_brush(brush)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(1)
	assert_str(connections[0].id).is_equal(&"boss_door")


func test_empty_id_is_preserved() -> void:
	var context := _make_context()
	var brush := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&""
	)
	context.brushes.add_brush(brush)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(1)
	assert_bool(connections[0].id == &"").is_true()


func test_duplicate_explicit_id_both_preserved() -> void:
	var context := _make_context()
	var first := _make_connection_brush(
		Vector2i(2, 3),
		ConnectionSide.Value.TOP,
		&"dup"
	)
	var second := _make_connection_brush(
		Vector2i(4, 3),
		ConnectionSide.Value.TOP,
		&"dup"
	)
	context.brushes.add_brush(first)
	context.brushes.add_brush(second)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(2)
	assert_str(connections[0].id).is_equal(&"dup")
	assert_str(connections[1].id).is_equal(&"dup")


func test_two_empty_ids_both_preserved() -> void:
	var context := _make_context()
	var first := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&""
	)
	var second := _make_connection_brush(
		Vector2i(0, 4),
		ConnectionSide.Value.TOP,
		&""
	)
	context.brushes.add_brush(first)
	context.brushes.add_brush(second)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(2)
	assert_bool(connections[0].id == &"").is_true()
	assert_bool(connections[1].id == &"").is_true()


# --- Deterministic ordering ---


func test_sort_by_side_and_position() -> void:
	var context := _make_context()
	var top_a := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&"top_a"
	)
	var top_b := _make_connection_brush(
		Vector2i(0, 1),
		ConnectionSide.Value.TOP,
		&"top_b"
	)
	var right := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.RIGHT,
		&"right"
	)
	var left := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.LEFT,
		&"left"
	)
	# Add out of order; expect side, then position.y, to drive the result.
	context.brushes.add_brush(left)
	context.brushes.add_brush(top_b)
	context.brushes.add_brush(right)
	context.brushes.add_brush(top_a)

	var connections := _run(context)

	var ids: Array[StringName] = []
	for connection in connections:
		ids.append(connection.id)

	assert_array(ids).contains_exactly([&"top_a", &"top_b", &"right", &"left"])


func test_sort_by_id_when_other_keys_tie() -> void:
	var context := _make_context()
	var second := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&"second"
	)
	var first := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&"first"
	)
	# Identical side, position and size; id must be the tiebreaker.
	context.brushes.add_brush(second)
	context.brushes.add_brush(first)

	var connections := _run(context)

	var ids: Array[StringName] = []
	for connection in connections:
		ids.append(connection.id)

	assert_array(ids).contains_exactly([&"first", &"second"])


func test_sort_by_size_when_side_and_position_tie() -> void:
	var context := _make_context()
	var wide := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&"wide",
		Vector2i(3, 1)
	)
	var narrow := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.TOP,
		&"narrow",
		Vector2i(1, 1)
	)
	# Identical side and position; the narrower opening must sort first.
	context.brushes.add_brush(wide)
	context.brushes.add_brush(narrow)

	var connections := _run(context)

	var ids: Array[StringName] = []
	for connection in connections:
		ids.append(connection.id)

	assert_array(ids).contains_exactly([&"narrow", &"wide"])


func test_sort_by_size_y_when_side_and_position_tie() -> void:
	var context := _make_context()
	var tall := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.LEFT,
		&"tall",
		Vector2i(1, 3)
	)
	var short := _make_connection_brush(
		Vector2i(0, 0),
		ConnectionSide.Value.LEFT,
		&"short",
		Vector2i(1, 2)
	)
	# Vertical openings have a fixed width, so their height must decide the order.
	context.brushes.add_brush(tall)
	context.brushes.add_brush(short)

	var connections := _run(context)

	var ids: Array[StringName] = []
	for connection in connections:
		ids.append(connection.id)

	assert_array(ids).contains_exactly([&"short", &"tall"])


# --- No silent repair ---


func test_overlapping_connections_both_recorded() -> void:
	var context := _make_context()
	var first := _make_connection_brush(
		Vector2i(2, 3),
		ConnectionSide.Value.TOP,
		&"overlap_a",
		Vector2i(3, 1)
	)
	var second := _make_connection_brush(
		Vector2i(2, 3),
		ConnectionSide.Value.TOP,
		&"overlap_b",
		Vector2i(3, 1)
	)
	context.brushes.add_brush(first)
	context.brushes.add_brush(second)

	var connections := _run(context)

	assert_int(connections.size()).is_equal(2)


# --- Fatal issues ---


func test_non_connection_brush_produces_fatal_issue_and_no_connection() -> void:
	var context := _make_context()
	var fake = auto_free(MockConnectionLikeBrush.new())
	fake.position = Vector2.ZERO
	context.brushes.add_brush(fake)

	var connections := _run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
	assert_int(connections.size()).is_zero()


func test_null_semantic_data_produces_fatal_issue() -> void:
	var context := _make_context()
	context.semantic_data = null

	var step := BakeConnectionsStep.new()
	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()


func test_null_brushes_produce_fatal_issue() -> void:
	var context := _make_context()
	context.brushes = null

	var step := BakeConnectionsStep.new()
	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
