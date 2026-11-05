## ThemeSaveStep unit tests.
## Covers: null checks, directory creation, and save operations.
extends GdUnitTestSuite


func _make_minimal_context() -> ThemeBuildContext:
	var context = ThemeBuildContext.new()
	context.theme_name = "test_theme"
	context.report = ThemeBuildReport.new()
	return context


# ── Null checks ──────────────────────────────────────────────────────

func test_missing_theme_tile_assets_reports_fatal() -> void:
	var step = ThemeSaveStep.new()
	var context = _make_minimal_context()
	# theme_tile_assets is null
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()


func test_missing_theme_info_reports_fatal() -> void:
	var step = ThemeSaveStep.new()
	var context = _make_minimal_context()
	context.theme_tile_assets = ThemeTileAssets.new()
	# theme_info is null
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()


func test_missing_tileset_reports_fatal() -> void:
	var step = ThemeSaveStep.new()
	var context = _make_minimal_context()
	context.theme_tile_assets = ThemeTileAssets.new()
	context.theme_info = ThemeInfo.new()
	# tileset is null
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()


# ── Directory creation ───────────────────────────────────────────────

func test_invalid_directory_reports_fatal() -> void:
	var step = ThemeSaveStep.new()
	var context = _make_minimal_context()
	context.theme_tile_assets = ThemeTileAssets.new()
	context.theme_info = ThemeInfo.new()
	context.tileset = TileSet.new()
	
	# Use an invalid theme name to get an invalid path
	context.theme_name = "/invalid/path/theme"
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()


# ── Successful save ──────────────────────────────────────────────────

# Note: We skip the actual save test because it writes to disk.
# The save boundary is tested via integration tests.

# ── Step metadata ────────────────────────────────────────────────────

func test_get_id_returns_theme_save() -> void:
	var step = ThemeSaveStep.new()
	assert_str(step.get_id()).is_equal(&"theme_save")


func test_get_display_name_returns_string() -> void:
	var step = ThemeSaveStep.new()
	assert_str(step.get_display_name()).is_not_empty()
