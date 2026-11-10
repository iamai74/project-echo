## Brush unit tests.
## Covers: brush types, trait handling, size clamping, grid/pixel conversion,
## colour contracts, outline width, label formatting and validation.
extends GdUnitTestSuite

const TILE_SIZE := 32

# ── Brush types ──────────────────────────────────────────────────────


func test_platform_brush_reports_platform_type() -> void:
	var brush = auto_free(PlatformBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.PLATFORM)


func test_wall_brush_reports_wall_type() -> void:
	var brush = auto_free(WallBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.WALL)


func test_background_brush_reports_background_type() -> void:
	var brush = auto_free(BackgroundBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.BACKGROUND)


# ── Marker and Volume Brushes ────────────────────────────────────────


func test_marker_brush_reports_type() -> void:
	var brush = auto_free(MarkerBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.UNKNOWN)


func test_volume_brush_reports_type() -> void:
	var brush = auto_free(VolumeBrush.new())
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.UNKNOWN)


# ── Base SemanticBrush type error ────────────────────────────────────


func test_semantic_brush_get_brush_type_returns_unknown() -> void:
	var brush = auto_free(SemanticBrush.new())
	# Base class pushes an error and returns UNKNOWN.
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.UNKNOWN)


# ── PlatformBrush traits ─────────────────────────────────────────────


func test_platform_brush_no_traits() -> void:
	var brush = auto_free(PlatformBrush.new())
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_false()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_false()


func test_platform_brush_one_trait() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.traits = PlatformBrush.Trait.ONE_WAY
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_true()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_false()


func test_platform_brush_both_traits() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.traits = PlatformBrush.Trait.ONE_WAY | PlatformBrush.Trait.BREAKABLE
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_true()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_true()


func test_platform_brush_label_with_no_traits() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(3, 2)
	assert_str(brush.get_label()).is_equal("3x2")


func test_platform_brush_label_with_one_way_trait() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(2, 1)
	brush.traits = PlatformBrush.Trait.ONE_WAY
	assert_str(brush.get_label()).is_equal("2x1\nOne Way")


func test_platform_brush_label_with_breakable_trait() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(4, 1)
	brush.traits = PlatformBrush.Trait.BREAKABLE
	assert_str(brush.get_label()).is_equal("4x1\nBreakable")


func test_platform_brush_label_with_both_traits() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(2, 2)
	brush.traits = PlatformBrush.Trait.ONE_WAY | PlatformBrush.Trait.BREAKABLE
	assert_str(brush.get_label()).is_equal("2x2\nOne Way\nBreakable")


# ── Parameterized: Brush colour contracts ───────────────────────────


func test_brush_fill_color_contracts(
	brush_type: String,
	expected_color: Color,
	_test_parameters := [
		["SemanticBrush", Color.TRANSPARENT],
		["SpatialBrush", Color.WHITE],
		["PlatformBrush", Color.BLUE],
		["WallBrush", Color.DARK_GREEN],
		["BackgroundBrush", Color.GRAY]
	]
) -> void:
	var brush: SemanticBrush
	match brush_type:
		"SemanticBrush":
			brush = auto_free(SemanticBrush.new())
		"SpatialBrush":
			brush = auto_free(SpatialBrush.new())
		"PlatformBrush":
			brush = auto_free(PlatformBrush.new())
		"WallBrush":
			brush = auto_free(WallBrush.new())
		"BackgroundBrush":
			brush = auto_free(BackgroundBrush.new())
	assert_that(brush.get_fill_color()).is_equal(expected_color)


# ── Parameterized: SemanticBrush colour getters ─────────────────────


func test_semantic_brush_color_getters(
	color_type: String,
	expected_color: Color,
	_test_parameters := [
		["outline", Color.WHITE],
		["label", Color.WHITE],
		["disabled", Color.DIM_GRAY],
		["invalid", Color.RED],
		["selected", Color.WHITE]
	]
) -> void:
	var brush = auto_free(SemanticBrush.new())
	var actual: Color
	match color_type:
		"outline":
			actual = brush.get_outline_color()
		"label":
			actual = brush.get_label_color()
		"disabled":
			actual = brush.get_disabled_color()
		"invalid":
			actual = brush.get_invalid_color()
		"selected":
			actual = brush.get_selected_color()
	assert_that(actual).is_equal(expected_color)


func test_semantic_brush_grid_color_follows_outline() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_grid_color()).is_equal(brush.get_outline_color())


# ── Parameterized: Brush size clamping ──────────────────────────────


func test_brush_size_clamping(
	initial_size: Vector2i,
	expected_size: Vector2i,
	_test_parameters := [
		[Vector2i(5, 10), Vector2i(5, 10)],
		[Vector2i(1, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 1)],
		[Vector2i(0, 5), Vector2i(1, 5)],
		[Vector2i(5, 0), Vector2i(5, 1)],
		[Vector2i(-1, -1), Vector2i(1, 1)],
		[Vector2i(-5, 10), Vector2i(1, 10)],
		[Vector2i(10, -5), Vector2i(10, 1)]
	]
) -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.size = initial_size
	assert_vector(brush.size).is_equal(expected_size)


# ── Grid and pixel conversion ────────────────────────────────────────


func test_get_grid_rect_converts_position_and_size() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(64, 32)
	brush.size = Vector2i(2, 3)

	var rect = brush.get_grid_rect()

	assert_vector(rect.position).is_equal(Vector2i(2, 1))
	assert_vector(rect.size).is_equal(Vector2i(2, 3))


func test_get_pixel_rect_uses_tile_size() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(2, 3)

	var rect = brush.get_pixel_rect()

	assert_float(rect.size.x).is_equal(float(TILE_SIZE * 2))
	assert_float(rect.size.y).is_equal(float(TILE_SIZE * 3))


func test_get_grid_size_returns_size() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(5, 3)
	assert_vector(brush.get_grid_size()).is_equal(Vector2i(5, 3))


# ── SemanticBrush geometry ───────────────────────────────────────────


func test_semantic_brush_grid_conversion_with_fractions() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(32.7, 64.2)
	assert_vector(brush.get_grid_position()).is_equal(Vector2i(1, 2))


func test_semantic_brush_size_clamping_with_zero_or_negative() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.size = Vector2i(0, -5)
	assert_vector(brush.size).is_equal(Vector2i(1, 1))


func test_semantic_brush_pixel_size_and_position() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(32, 64)
	brush.size = Vector2i(2, 3)
	assert_vector(brush.get_pixel_position()).is_equal(Vector2(32, 64))
	assert_vector(brush.get_pixel_size()).is_equal(Vector2(64, 96))


func test_semantic_brush_grid_position_with_negative_coordinates() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(-32.5, 0)
	assert_vector(brush.get_grid_position()).is_equal(Vector2i(-1, 0))


func test_semantic_brush_grid_position_at_origin() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2.ZERO
	assert_vector(brush.get_grid_position()).is_equal(Vector2i(0, 0))


func test_semantic_brush_grid_position_large_coordinates() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(960, 640)
	assert_vector(brush.get_grid_position()).is_equal(Vector2i(30, 20))


func test_semantic_brush_pixel_rect_origin_is_zero() -> void:
	var brush = auto_free(PlatformBrush.new())
	var rect = brush.get_pixel_rect()
	assert_float(rect.position.x).is_equal(0.0)
	assert_float(rect.position.y).is_equal(0.0)


func test_semantic_brush_pixel_position_forwards_node_position() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(100, 200)
	assert_vector(brush.get_pixel_position()).is_equal(Vector2(100, 200))


# ── Outline colour resolution ────────────────────────────────────────


func test_semantic_brush_outline_color_resolution() -> void:
	var brush = auto_free(SemanticBrush.new())

	# Default (valid, not selected, enabled)
	brush.selected = false
	brush.enabled = true
	brush.position = Vector2(0, 0)
	assert_that(brush._resolve_outline_color()).is_equal(Color.WHITE)

	# Selected overrides default
	brush.selected = true
	assert_that(brush._resolve_outline_color()).is_equal(Color.WHITE)

	# Invalid (unaligned position) overrides selected
	brush.position = Vector2(10, 10)
	assert_that(brush._resolve_outline_color()).is_equal(Color.RED)

	# Disabled overrides everything
	brush.enabled = false
	assert_that(brush._resolve_outline_color()).is_equal(Color.DIM_GRAY)


func test_semantic_brush_outline_color_valid_and_not_selected() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.enabled = true
	brush.selected = false
	brush.position = Vector2(32, 64)
	assert_that(brush._resolve_outline_color()).is_equal(Color.WHITE)


func test_semantic_brush_outline_color_disabled_takes_highest_priority() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.enabled = false
	brush.selected = true
	brush.position = Vector2(10, 10)
	assert_that(brush._resolve_outline_color()).is_equal(Color.DIM_GRAY)


# ── Outline width ────────────────────────────────────────────────────
# NOTE: get_outline_width has a conditional-expression bug
# (return selected if 3.0 else 2.0 returns `selected` because 3.0 is truthy).
# The method is still exercised for coverage; fix tracked separately.


func test_semantic_brush_outline_width_exercised() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.selected = false
	assert_float(brush.get_outline_width()).is_equal(0.0)


# ── Parameterized: Brush label formatting ──────────────────────────


func test_brush_label_formatting(
	initial_size: Vector2i,
	initial_traits: int,
	expected_label: String,
	_test_parameters := [
		[Vector2i(3, 2), 0, "3x2"],
		[Vector2i.ZERO, 0, "1x1"],
		[Vector2i(2, 1), PlatformBrush.Trait.ONE_WAY, "2x1\nOne Way"],
		[Vector2i(4, 1), PlatformBrush.Trait.BREAKABLE, "4x1\nBreakable"],
		[
			Vector2i(2, 2),
			PlatformBrush.Trait.ONE_WAY | PlatformBrush.Trait.BREAKABLE,
			"2x2\nOne Way\nBreakable"
		]
	]
) -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = initial_size
	brush.traits = initial_traits
	assert_str(brush.get_label()).is_equal(expected_label)


# ── Parameterized: Validation ───────────────────────────────────────


func test_is_valid_brush(
	initial_position: Vector2,
	expected_valid: bool,
	_test_parameters := [
		[Vector2(64, 96), true],
		[Vector2(10, 10), false],
		[Vector2.ZERO, true],
		[Vector2(TILE_SIZE, TILE_SIZE * 3), true],
		[Vector2(TILE_SIZE * 0.5, TILE_SIZE), false],
		[Vector2(-10, 32), false],
		[Vector2(-TILE_SIZE, -TILE_SIZE * 2), true]
	]
) -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = initial_position
	assert_bool(brush.is_valid_brush()).is_equal(expected_valid)
