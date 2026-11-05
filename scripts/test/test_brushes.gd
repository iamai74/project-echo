## Brush unit tests.
## Covers: brush types, trait handling, size clamping, grid/pixel conversion,
## and validation.
extends GdUnitTestSuite


const TILE_SIZE := 32


# ── Brush types ──────────────────────────────────────────────────────

func test_platform_brush_reports_platform_type() -> void:
	var brush = PlatformBrush.new()
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.PLATFORM)


func test_wall_brush_reports_wall_type() -> void:
	var brush = WallBrush.new()
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.WALL)


func test_background_brush_reports_background_type() -> void:
	var brush = BackgroundBrush.new()
	assert_int(brush.get_brush_type()).is_equal(SemanticBrush.BrushType.BACKGROUND)


# ── PlatformBrush traits ─────────────────────────────────────────────

func test_platform_brush_no_traits() -> void:
	var brush = PlatformBrush.new()
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_false()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_false()


func test_platform_brush_one_trait() -> void:
	var brush = PlatformBrush.new()
	brush.traits = PlatformBrush.Trait.ONE_WAY
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_true()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_false()


func test_platform_brush_both_traits() -> void:
	var brush = PlatformBrush.new()
	brush.traits = PlatformBrush.Trait.ONE_WAY | PlatformBrush.Trait.BREAKABLE
	assert_bool(brush.has_trait(PlatformBrush.Trait.ONE_WAY)).is_true()
	assert_bool(brush.has_trait(PlatformBrush.Trait.BREAKABLE)).is_true()


# ── Size clamping ────────────────────────────────────────────────────

func test_brush_size_clamps_values_below_one() -> void:
	var brush = PlatformBrush.new()
	brush.size = Vector2i(-1, 0)
	assert_int(brush.size.x).is_equal(1)
	assert_int(brush.size.y).is_equal(1)


# ── Grid and pixel conversion ────────────────────────────────────────

func test_get_grid_rect_converts_position_and_size() -> void:
	var brush = PlatformBrush.new()
	brush.position = Vector2(64, 32)
	brush.size = Vector2i(2, 3)
	
	var rect = brush.get_grid_rect()
	
	assert_vector(rect.position).is_equal(Vector2i(2, 1))
	assert_vector(rect.size).is_equal(Vector2i(2, 3))


func test_get_pixel_rect_uses_tile_size() -> void:
	var brush = PlatformBrush.new()
	brush.size = Vector2i(2, 3)
	
	var rect = brush.get_pixel_rect()
	
	assert_float(rect.size.x).is_equal(float(TILE_SIZE * 2))
	assert_float(rect.size.y).is_equal(float(TILE_SIZE * 3))


# ── Validation ───────────────────────────────────────────────────────

func test_is_valid_brush_accepts_aligned_positions() -> void:
	var brush = PlatformBrush.new()
	brush.position = Vector2(64, 96)
	
	assert_bool(brush.is_valid_brush()).is_true()


func test_is_valid_brush_rejects_unaligned_positions() -> void:
	var brush = PlatformBrush.new()
	brush.position = Vector2(10, 10)
	
	assert_bool(brush.is_valid_brush()).is_false()
