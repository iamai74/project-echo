## ThemeSaveStep unit tests.
## Covers: null checks, directory creation, successful saves and save failures.
## Saves go to a temporary user:// directory and are cleaned up afterwards.
extends GdUnitTestSuite


const TEMP_ROOT := "user://test_theme_save"


class TempThemeBuildContext:
	extends ThemeBuildContext

	var resource_dir: String

	func get_resource_dir() -> String:
		return resource_dir


func before_test() -> void:
	_remove_dir(TEMP_ROOT)
	DirAccess.make_dir_recursive_absolute(TEMP_ROOT)


func after_test() -> void:
	_remove_dir(TEMP_ROOT)


func _make_context(theme_name: String) -> TempThemeBuildContext:
	var context := TempThemeBuildContext.new()
	context.theme_name = theme_name
	context.resource_dir = TEMP_ROOT.path_join(theme_name) + "/"
	context.report = ThemeBuildReport.new()
	return context


func _fill_required_resources(context: ThemeBuildContext) -> void:
	context.theme_tile_assets = ThemeTileAssets.new()
	context.theme_info = ThemeInfo.new()
	context.tileset = TileSet.new()


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if entry != "." and entry != "..":
				var entry_path := path.path_join(entry)
				if dir.current_is_dir():
					_remove_dir(entry_path)
				else:
					DirAccess.remove_absolute(entry_path)
			entry = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(path)


# ── Null checks ──────────────────────────────────────────────────────

func test_missing_theme_tile_assets_reports_fatal() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()


func test_missing_theme_info_reports_fatal() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")
	context.theme_tile_assets = ThemeTileAssets.new()

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()


func test_missing_tileset_reports_fatal() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")
	context.theme_tile_assets = ThemeTileAssets.new()
	context.theme_info = ThemeInfo.new()

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()


# ── Directory creation ───────────────────────────────────────────────

func test_invalid_directory_reports_fatal() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")
	_fill_required_resources(context)

	var blocker := TEMP_ROOT.path_join("blocker")
	var file := FileAccess.open(blocker, FileAccess.WRITE)
	file.store_string("not a directory")
	file.close()
	# A file cannot act as the parent of the theme directory.
	context.resource_dir = blocker.path_join("theme")

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()


# ── Successful save ──────────────────────────────────────────────────

func test_successful_save_writes_all_theme_resources() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")
	_fill_required_resources(context)
	var prefix := context.get_resource_prefix()

	step.run(context)

	assert_bool(context.report.has_fatal()).is_false()
	assert_bool(FileAccess.file_exists(prefix + "_tile_assets.tres")).is_true()
	assert_bool(FileAccess.file_exists(prefix + "_theme.tres")).is_true()
	assert_bool(FileAccess.file_exists(prefix + "_tileset.tres")).is_true()


# ── Save failure ─────────────────────────────────────────────────────

func test_save_failure_reports_fatal_and_stops_later_saves() -> void:
	var step := ThemeSaveStep.new()
	var context := _make_context("test_theme")
	_fill_required_resources(context)
	var prefix := context.get_resource_prefix()

	# Occupy the first save path with a directory so ResourceSaver fails.
	DirAccess.make_dir_recursive_absolute(prefix + "_tile_assets.tres")

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()
	assert_bool(FileAccess.file_exists(prefix + "_theme.tres")).is_false()
	assert_bool(FileAccess.file_exists(prefix + "_tileset.tres")).is_false()


# ── Step metadata ────────────────────────────────────────────────────

func test_get_id_returns_theme_save() -> void:
	var step := ThemeSaveStep.new()
	assert_str(step.get_id()).is_equal(&"theme_save")


func test_get_display_name_returns_string() -> void:
	var step := ThemeSaveStep.new()
	assert_str(step.get_display_name()).is_not_empty()
