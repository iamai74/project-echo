## ThemeAssetsLoadStep unit tests.
## Covers: step metadata, slice name parsing, tile type matching,
## variant extraction, category extraction, and error paths.
extends GdUnitTestSuite


var step: ThemeAssetsLoadStep


func before_test() -> void:
	step = ThemeAssetsLoadStep.new()


# --- Step metadata ---

func test_get_id_returns_theme_assets_load() -> void:
	assert_str(step.get_id()).is_equal(&"theme_assets_load")


func test_get_display_name_returns_string() -> void:
	assert_str(step.get_display_name()).is_not_empty()


# --- _parse_slice_name: table-driven parameterized tests ---

func test_parse_slice_name(
	initial_slice_name: String,
	expected_category: String,
	expected_tile_type: String,
	expected_variant: String,
	_test_parameters := [
		["platform_single_0", "platform", "single", "0"],
		["walls_top_left_1", "walls", "top_left", "1"],
		["background_0", "background", "", "0"],
		["platform_full_2", "platform", "full", "2"],
		["platform_single_top_0", "platform", "single_top", "0"],
		["unknown_single_0", "", "", ""],
		["platform_unknowntype_0", "", "", ""],
		["platform_single", "", "", ""],
		["", "", "", ""]
	]
) -> void:
	var result = step._parse_slice_name(initial_slice_name)
	assert_str(result.get("category", "")).is_equal(expected_category)
	assert_str(result.get("tile_type", "")).is_equal(expected_tile_type)
	assert_str(result.get("variant", "")).is_equal(expected_variant)


# --- _extract_variant: table-driven parameterized tests ---

func test_extract_variant(
	initial_input: String,
	expected_variant: String,
	_test_parameters := [
		["platform_single_0", "0"],
		["walls_full_42", "42"],
		["no_number_here", ""],
		["", ""],
		["single_99", "99"]
	]
) -> void:
	var variant = step._extract_variant(initial_input)
	assert_str(variant).is_equal(expected_variant)


# --- _extract_category: table-driven parameterized tests ---

func test_extract_category(
	initial_input: String,
	expected_category: String,
	_test_parameters := [
		["platform_single", "platform"],
		["walls_top", "walls"],
		["background", "background"],
		["unknown_type", ""],
		["", ""]
	]
) -> void:
	var cat = step._extract_category(initial_input)
	assert_str(cat).is_equal(expected_category)


# --- _match_tile_type: table-driven parameterized tests ---

func test_match_tile_type(
	initial_input: String,
	expected_tile_type: String,
	_test_parameters := [
		["single", "single"],
		["full", "full"],
		["single_bottom", "single_bottom"],
		["unknown_tile", ""],
		["", ""],
		["single_top", "single_top"]
	]
) -> void:
	var matched = step._match_tile_type(initial_input)
	assert_str(matched).is_equal(expected_tile_type)


# --- Error paths ---

func test_run_file_not_found_produces_fatal_issue() -> void:
	var context = ThemeBuildContext.new()
	context.theme_name = "nonexistent_theme_xyz"
	context.report = ThemeBuildReport.new()

	step.run(context)

	assert_bool(context.report.has_fatal()).is_true()


func test_run_missing_file_issue_type_is_file_not_found() -> void:
	var context = ThemeBuildContext.new()
	context.theme_name = "nonexistent_theme_xyz"
	context.report = ThemeBuildReport.new()

	step.run(context)

	var all_issues = context.report.get_all_issues()
	assert_bool(all_issues.has(ThemeBuildIssue.IssueType.FILE_NOT_FOUND)).is_true()
