## BakeMarkersStep unit tests.
## Covers: step metadata, marker data generation from enabled marker brushes,
## disabled-brush skipping, duplicate preservation, empty content_id handling,
## fatal issues for non-marker brushes and missing inputs.
extends GdUnitTestSuite


const TILE_SIZE := 32


# A brush that reports the MARKER type but is not a MarkerBrush, used to prove
# the step records a fatal issue when a cast to MarkerBrush fails.
class MockMarkerLikeBrush:
	extends SemanticBrush


	func get_brush_type() -> SemanticBrush.BrushType:
		return SemanticBrush.BrushType.MARKER


# --- Helpers ---


func _make_context() -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.brushes = BrushCollection.new()
	return context


func _make_marker_brush(
	grid_position: Vector2i,
	marker_type: MarkerType.Value,
	content_id: StringName,
	marker_id: StringName,
	enabled: bool = true
) -> MarkerBrush:
	var brush = auto_free(MarkerBrush.new())
	brush.position = Vector2(grid_position.x * TILE_SIZE, grid_position.y * TILE_SIZE)
	brush.marker_type = marker_type
	brush.content_id = content_id
	brush.marker_id = marker_id
	brush.enabled = enabled
	return brush


# --- Step metadata ---


func test_get_id_returns_bake_markers() -> void:
	var step := BakeMarkersStep.new()
	assert_str(step.get_id()).is_equal(&"bake_markers")


func test_get_display_name_returns_string() -> void:
	var step := BakeMarkersStep.new()
	assert_str(step.get_display_name()).is_not_empty()


# --- Marker data generation ---


func test_enabled_marker_brush_produces_marker_with_copied_fields() -> void:
	var context := _make_context()
	var brush := _make_marker_brush(
		Vector2i(2, 3),
		MarkerType.Value.LOOT_SPAWN,
		&"chest_gold",
		&"loot_01"
	)
	context.brushes.add_brush(brush)

	var step := BakeMarkersStep.new()
	step.run(context)

	var markers := context.semantic_data.markers.get_markers(MarkerType.Value.LOOT_SPAWN)
	assert_int(markers.size()).is_equal(1)

	var marker: MarkerData = markers[0]
	assert_int(marker.type).is_equal(MarkerType.Value.LOOT_SPAWN)
	assert_vector(marker.position).is_equal(Vector2i(2, 3))
	assert_str(marker.content_id).is_equal(&"chest_gold")
	assert_str(marker.marker_id).is_equal(&"loot_01")


func test_disabled_marker_brush_produces_no_marker() -> void:
	var context := _make_context()
	var brush := _make_marker_brush(
		Vector2i(1, 1),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"spawn_01",
		false
	)
	context.brushes.add_brush(brush)

	var step := BakeMarkersStep.new()
	step.run(context)

	assert_int(context.semantic_data.markers.get_all_markers().size()).is_zero()


func test_duplicate_markers_are_preserved() -> void:
	var context := _make_context()
	var first := _make_marker_brush(
		Vector2i(2, 3),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"spawn_a"
	)
	var second := _make_marker_brush(
		Vector2i(2, 3),
		MarkerType.Value.ENEMY_SPAWN,
		&"enemy_goblin",
		&"spawn_b"
	)
	context.brushes.add_brush(first)
	context.brushes.add_brush(second)

	var step := BakeMarkersStep.new()
	step.run(context)

	var markers := context.semantic_data.markers.get_markers(MarkerType.Value.ENEMY_SPAWN)
	assert_int(markers.size()).is_equal(2)


func test_empty_content_id_is_recorded() -> void:
	var context := _make_context()
	var brush := _make_marker_brush(
		Vector2i(0, 0),
		MarkerType.Value.CHECKPOINT,
		&"",
		&"checkpoint_01"
	)
	context.brushes.add_brush(brush)

	var step := BakeMarkersStep.new()
	step.run(context)

	var markers := context.semantic_data.markers.get_markers(MarkerType.Value.CHECKPOINT)
	assert_int(markers.size()).is_equal(1)
	assert_str(markers[0].content_id).is_equal(&"")


# --- Fatal issues ---


func test_non_marker_brush_produces_fatal_issue_and_no_marker() -> void:
	var context := _make_context()
	var fake = auto_free(MockMarkerLikeBrush.new())
	fake.position = Vector2.ZERO
	context.brushes.add_brush(fake)

	var step := BakeMarkersStep.new()
	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
	assert_int(context.semantic_data.markers.get_all_markers().size()).is_zero()


func test_null_semantic_data_produces_fatal_issue() -> void:
	var context := _make_context()
	context.semantic_data = null

	var step := BakeMarkersStep.new()
	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()


func test_null_brushes_produce_fatal_issue() -> void:
	var context := _make_context()
	context.brushes = null

	var step := BakeMarkersStep.new()
	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()
