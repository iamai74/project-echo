## ConnectionPointBrush unit tests.
## Covers: brush type, default side, orientation validation per side,
## grid misalignment, label formatting and colour contract.
extends GdUnitTestSuite

# ── Brush type ───────────────────────────────────────────────────────


func test_connection_point_brush_reports_type() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.CONNECTION_POINT)


# ── Default fields ───────────────────────────────────────────────────


func test_connection_point_brush_default_side_is_top() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	assert_int(brush.side).is_equal(ConnectionSide.Value.TOP)


func test_connection_point_brush_default_connection_id_is_empty() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	assert_bool(brush.connection_id == &"").is_true()


# ── Orientation validation ───────────────────────────────────────────


func test_top_side_valid_only_with_size_y_one() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2.ZERO
	brush.side = ConnectionSide.Value.TOP

	brush.size = Vector2i(3, 1)
	assert_bool(brush.is_valid_brush()).is_true()

	brush.size = Vector2i(3, 2)
	assert_bool(brush.is_valid_brush()).is_false()


func test_bottom_side_valid_only_with_size_y_one() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2.ZERO
	brush.side = ConnectionSide.Value.BOTTOM

	brush.size = Vector2i(1, 1)
	assert_bool(brush.is_valid_brush()).is_true()

	brush.size = Vector2i(1, 2)
	assert_bool(brush.is_valid_brush()).is_false()


func test_left_side_valid_only_with_size_x_one() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2.ZERO
	brush.side = ConnectionSide.Value.LEFT

	brush.size = Vector2i(1, 3)
	assert_bool(brush.is_valid_brush()).is_true()

	brush.size = Vector2i(2, 3)
	assert_bool(brush.is_valid_brush()).is_false()


func test_right_side_valid_only_with_size_x_one() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2.ZERO
	brush.side = ConnectionSide.Value.RIGHT

	brush.size = Vector2i(1, 5)
	assert_bool(brush.is_valid_brush()).is_true()

	brush.size = Vector2i(2, 5)
	assert_bool(brush.is_valid_brush()).is_false()


# ── Grid alignment still gates validity ──────────────────────────────


func test_connection_point_brush_invalid_when_not_grid_aligned() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2(10, 10)
	brush.side = ConnectionSide.Value.TOP
	brush.size = Vector2i(3, 1)
	assert_bool(brush.is_valid_brush()).is_false()


func test_unknown_side_is_invalid_and_labelled_with_raw_value() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.position = Vector2.ZERO
	brush.size = Vector2i(3, 1)
	brush.side = 99
	assert_bool(brush.is_valid_brush()).is_false()
	assert_str(brush.get_label()).is_equal("99\n<missing connection_id>\n3x1")


# ── Label ────────────────────────────────────────────────────────────


func test_connection_point_brush_label_includes_side_id_and_size() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.side = ConnectionSide.Value.TOP
	brush.connection_id = &"main_exit"
	brush.size = Vector2i(3, 1)
	assert_str(brush.get_label()).is_equal("TOP\nmain_exit\n3x1")


func test_connection_point_brush_label_changes_with_side() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.connection_id = &"main_exit"
	brush.size = Vector2i(1, 3)
	brush.side = ConnectionSide.Value.LEFT
	assert_str(brush.get_label()).is_equal("LEFT\nmain_exit\n1x3")


func test_connection_point_brush_label_flags_missing_connection_id() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	brush.side = ConnectionSide.Value.BOTTOM
	brush.size = Vector2i(2, 1)
	assert_str(brush.get_label()).is_equal("BOTTOM\n<missing connection_id>\n2x1")


# ── Colour contract ──────────────────────────────────────────────────


func test_connection_point_brush_fill_is_translucent_cyan() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	var fill: Color = brush.get_fill_color()
	# Translucent cyan: cyan RGB with a reduced, non-zero alpha.
	assert_float(fill.r).is_equal(0.0)
	assert_float(fill.g).is_equal(1.0)
	assert_float(fill.b).is_equal(1.0)
	assert_bool(fill.a > 0.0 and fill.a < 1.0).is_true()


func test_connection_point_brush_outline_is_cyan() -> void:
	var brush = auto_free(ConnectionPointBrush.new())
	var outline: Color = brush.get_outline_color()
	# Fully opaque cyan.
	assert_that(outline).is_equal(Color.CYAN)
	assert_float(outline.a).is_equal(1.0)
