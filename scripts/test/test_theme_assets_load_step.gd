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


# --- _parse_slice_name: successful parses ---

func test_parse_platform_single_variant() -> void:
	var result = step._parse_slice_name("platform_single_0")
	assert_str(result.get("category", "")).is_equal("platform")
	assert_str(result.get("tile_type", "")).is_equal("single")
	assert_str(result.get("variant", "")).is_equal("0")


func test_parse_walls_top_left_variant() -> void:
	var result = step._parse_slice_name("walls_top_left_1")
	assert_str(result.get("category", "")).is_equal("walls")
	assert_str(result.get("tile_type", "")).is_equal("top_left")
	assert_str(result.get("variant", "")).is_equal("1")


func test_parse_background_variant() -> void:
	var result = step._parse_slice_name("background_0")
	assert_str(result.get("category", "")).is_equal("background")
	assert_str(result.get("tile_type", "")).is_equal("")
	assert_str(result.get("variant", "")).is_equal("0")


func test_parse_platform_full_variant() -> void:
	var result = step._parse_slice_name("platform_full_2")
	assert_str(result.get("category", "")).is_equal("platform")
	assert_str(result.get("tile_type", "")).is_equal("full")
	assert_str(result.get("variant", "")).is_equal("2")


func test_parse_platform_single_top_variant() -> void:
	var result = step._parse_slice_name("platform_single_top_0")
	assert_str(result.get("category", "")).is_equal("platform")
	assert_str(result.get("tile_type", "")).is_equal("single_top")
	assert_str(result.get("variant", "")).is_equal("0")


# --- _parse_slice_name: invalid names ---

func test_parse_unknown_category_returns_empty() -> void:
	var result = step._parse_slice_name("unknown_single_0")
	assert_bool(result.is_empty()).is_true()


func test_parse_unknown_tile_type_returns_empty() -> void:
	var result = step._parse_slice_name("platform_unknowntype_0")
	assert_bool(result.is_empty()).is_true()


func test_parse_no_variant_returns_empty() -> void:
	var result = step._parse_slice_name("platform_single")
	assert_bool(result.is_empty()).is_true()


func test_parse_empty_string_returns_empty() -> void:
	var result = step._parse_slice_name("")
	assert_bool(result.is_empty()).is_true()


# --- _extract_variant ---

func test_extract_variant_simple() -> void:
	var variant = step._extract_variant("platform_single_0")
	assert_str(variant).is_equal("0")


func test_extract_variant_multi_digit() -> void:
	var variant = step._extract_variant("walls_full_42")
	assert_str(variant).is_equal("42")


func test_extract_variant_no_number_returns_empty() -> void:
	var variant = step._extract_variant("no_number_here")
	assert_str(variant).is_empty()


# --- _extract_category ---

func test_extract_category_platform() -> void:
	var cat = step._extract_category("platform_single")
	assert_str(cat).is_equal("platform")


func test_extract_category_walls() -> void:
	var cat = step._extract_category("walls_top")
	assert_str(cat).is_equal("walls")


func test_extract_category_background() -> void:
	var cat = step._extract_category("background")
	assert_str(cat).is_equal("background")


func test_extract_category_unknown_returns_empty() -> void:
	var cat = step._extract_category("unknown_type")
	assert_str(cat).is_empty()


# --- _match_tile_type ---

func test_match_tile_type_known() -> void:
	var matched = step._match_tile_type("single")
	assert_str(matched).is_equal("single")


func test_match_tile_type_full() -> void:
	var matched = step._match_tile_type("full")
	assert_str(matched).is_equal("full")


func test_match_tile_type_single_bottom() -> void:
	var matched = step._match_tile_type("single_bottom")
	assert_str(matched).is_equal("single_bottom")


func test_match_tile_type_unknown_returns_empty() -> void:
	var matched = step._match_tile_type("unknown_tile")
	assert_str(matched).is_empty()


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
