## AuthoringBrushValidator unit tests.
## Covers: grid alignment for every known brush type, UNKNOWN brush warnings,
## disabled-brush skipping, null-entry skipping, one issue per bad brush,
## issue positions, and that marker size and connection orientation are ignored.
extends GdUnitTestSuite


# --- Helpers ---


func _make_context() -> RoomBakeContext:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.brushes = BrushCollection.new()
	return context


func _make_platform(position: Vector2, enabled: bool = true) -> PlatformBrush:
	var brush = auto_free(PlatformBrush.new())
	brush.position = position
	brush.enabled = enabled
	return brush


func _make_marker(position: Vector2, enabled: bool = true) -> MarkerBrush:
	var brush = auto_free(MarkerBrush.new())
	brush.position = position
	brush.enabled = enabled
	return brush


func _make_connection(position: Vector2, enabled: bool = true) -> ConnectionPointBrush:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = position
	brush.enabled = enabled
	return brush


func _make_unknown(position: Vector2, enabled: bool = true) -> VolumeBrush:
	var brush = auto_free(VolumeBrush.new())
	brush.position = position
	brush.enabled = enabled
	return brush


func _validate(context: RoomBakeContext) -> void:
	AuthoringBrushValidator.new().validate(context)


func _issues_of(context: RoomBakeContext, type: BakeIssue.IssueType) -> Array:
	return context.report.get_all_issues().get(type, [])


# --- Grid alignment: aligned brushes produce no issue ---


func test_aligned_platform_produces_no_issue() -> void:
	var context := _make_context()
	var tile_size := World.settings.tile_size
	context.brushes.add_brush(_make_platform(Vector2(tile_size * 3, tile_size * 4)))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Grid alignment: misaligned known brushes produce an ERROR ---


func test_misaligned_platform_produces_error() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_platform(Vector2(10, 10)))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


func test_misaligned_marker_produces_error() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_marker(Vector2(10, 10)))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


func test_misaligned_connection_produces_error() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_connection(Vector2(10, 10)))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.ERROR)


# --- Marker size and connection orientation are not checked here ---


func test_stretched_aligned_marker_produces_no_issue() -> void:
	# Size is an authoring fact owned by MarkerPlacementValidator, not this one.
	var context := _make_context()
	var tile_size := World.settings.tile_size
	var brush := _make_marker(Vector2(tile_size, tile_size), true)
	brush.size = Vector2i(3, 3)
	context.brushes.add_brush(brush)

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


func test_misoriented_aligned_connection_produces_no_issue() -> void:
	# Orientation is owned by ConnectionPointValidator, not this one.
	var context := _make_context()
	var tile_size := World.settings.tile_size
	var brush := _make_connection(Vector2(tile_size, tile_size), true)
	brush.size = Vector2i(3, 3)
	brush.side = ConnectionSide.Value.TOP
	context.brushes.add_brush(brush)

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Disabled brushes are skipped ---


func test_disabled_misaligned_brush_produces_no_issue() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_platform(Vector2(10, 10), false))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- UNKNOWN brushes produce a WARNING, not an ERROR ---


func test_unknown_enabled_brush_produces_warning() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_unknown(Vector2.ZERO, true))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.WARNING)


func test_unknown_brush_is_not_an_error_even_when_misaligned() -> void:
	# An UNKNOWN brush is reported as a warning regardless of grid alignment.
	var context := _make_context()
	context.brushes.add_brush(_make_unknown(Vector2(10, 10), true))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_bool(context.report.is_has_saverity(BakeIssue.Severity.ERROR)).is_false()
	assert_int(issues[0].severity).is_equal(BakeIssue.Severity.WARNING)


func test_unknown_disabled_brush_produces_no_issue() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_unknown(Vector2.ZERO, false))

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- One issue per bad brush ---


func test_multiple_bad_brushes_produce_one_issue_each() -> void:
	var context := _make_context()
	context.brushes.add_brush(_make_platform(Vector2(10, 10)))
	context.brushes.add_brush(_make_marker(Vector2(20, 20)))
	context.brushes.add_brush(_make_connection(Vector2(30, 30)))
	context.brushes.add_brush(_make_unknown(Vector2(40, 40)))

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(4)


# --- A missing brush collection is ignored, not a crash ---


func test_null_brush_collection_produces_no_issue() -> void:
	var context := RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()

	_validate(context)

	assert_bool(context.report.is_has_issues()).is_false()


# --- Issue position follows the brush grid position ---


func test_misaligned_issue_reports_grid_position() -> void:
	var context := _make_context()
	var tile_size := World.settings.tile_size
	var brush := _make_platform(Vector2(tile_size * 3 + 5, tile_size * 2 + 7))
	context.brushes.add_brush(brush)

	_validate(context)

	var issues := _issues_of(context, BakeIssue.IssueType.BRUSH_INVALID)
	assert_int(issues.size()).is_equal(1)
	assert_vector(issues[0].position).is_equal(brush.get_grid_position())
