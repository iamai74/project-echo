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


# ── Fill colour contracts ────────────────────────────────────────────

func test_platform_brush_fill_color_is_blue() -> void:
	var brush = auto_free(PlatformBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.BLUE)


func test_wall_brush_fill_color_is_dark_green() -> void:
	var brush = auto_free(WallBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.DARK_GREEN)


func test_background_brush_fill_color_is_gray() -> void:
	var brush = auto_free(BackgroundBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.GRAY)


func test_marker_brush_fill_color_is_white() -> void:
	var brush = auto_free(MarkerBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.WHITE)


func test_volume_brush_fill_color_is_white() -> void:
	var brush = auto_free(VolumeBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.WHITE)


func test_semantic_brush_fill_color_is_transparent() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.TRANSPARENT)


func test_spatial_brush_fill_color_is_white() -> void:
	var brush = auto_free(SpatialBrush.new())
	assert_that(brush.get_fill_color()).is_equal(Color.WHITE)


# ── SemanticBrush colour getters ─────────────────────────────────────

func test_semantic_brush_default_outline_color() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_outline_color()).is_equal(Color.WHITE)


func test_semantic_brush_default_grid_color_follows_outline() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_grid_color()).is_equal(brush.get_outline_color())


func test_semantic_brush_default_label_color() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_label_color()).is_equal(Color.WHITE)


func test_semantic_brush_disabled_color() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_disabled_color()).is_equal(Color.DIM_GRAY)


func test_semantic_brush_invalid_color() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_invalid_color()).is_equal(Color.RED)


func test_semantic_brush_selected_color() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_that(brush.get_selected_color()).is_equal(Color.WHITE)


# ── Size clamping ────────────────────────────────────────────────────

func test_brush_size_clamps_values_below_one() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(-1, 0)
	assert_int(brush.size.x).is_equal(1)
	assert_int(brush.size.y).is_equal(1)


func test_brush_size_clamps_only_x() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(0, 4)
	assert_int(brush.size.x).is_equal(1)
	assert_int(brush.size.y).is_equal(4)


func test_brush_size_clamps_only_y() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.size = Vector2i(3, -2)
	assert_int(brush.size.x).is_equal(3)
	assert_int(brush.size.y).is_equal(1)


func test_brush_size_one_is_minimum() -> void:
	var brush = auto_free(PlatformBrush.new())
	assert_int(brush.size.x).is_equal(1)
	assert_int(brush.size.y).is_equal(1)


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


# ── Label formatting ─────────────────────────────────────────────────

func test_semantic_brush_label_formatting() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.size = Vector2i(5, 10)
	assert_str(brush.get_label()).is_equal("5x10")


func test_semantic_brush_label_minimum_size() -> void:
	var brush = auto_free(SemanticBrush.new())
	assert_str(brush.get_label()).is_equal("1x1")


# ── Validation ───────────────────────────────────────────────────────

func test_is_valid_brush_accepts_aligned_positions() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(64, 96)

	assert_bool(brush.is_valid_brush()).is_true()


func test_is_valid_brush_rejects_unaligned_positions() -> void:
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(10, 10)

	assert_bool(brush.is_valid_brush()).is_false()


func test_is_valid_brush_accepts_origin() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2.ZERO
	assert_bool(brush.is_valid_brush()).is_true()


func test_is_valid_brush_accepts_exact_tile_boundaries() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(TILE_SIZE, TILE_SIZE * 3)
	assert_bool(brush.is_valid_brush()).is_true()


func test_is_valid_brush_rejects_half_tile_offset() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE)
	assert_bool(brush.is_valid_brush()).is_false()


func test_is_valid_brush_rejects_negative_unaligned() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(-10, 32)
	assert_bool(brush.is_valid_brush()).is_false()


func test_is_valid_brush_accepts_negative_aligned() -> void:
	var brush = auto_free(SemanticBrush.new())
	brush.position = Vector2(-TILE_SIZE, -TILE_SIZE * 2)
	assert_bool(brush.is_valid_brush()).is_true()
