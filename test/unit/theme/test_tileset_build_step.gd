## TileSetBuildStep unit tests.
## Covers: pure helpers, tile collection, tile mapping, and collision assignment.
## Loading real textures belongs in an integration test.
extends GdUnitTestSuite


const TILE_PACK_FIELDS := [
	"single",
	"single_all",
	"single_top",
	"single_bottom",
	"single_left",
	"single_right",
	"top",
	"bottom",
	"left",
	"right",
	"full",
	"top_left",
	"top_right",
	"bottom_left",
	"bottom_right",
]


# ── Missing ThemeTileAssets adds fatal issue ─────────────────────────

func test_missing_theme_tile_assets_adds_fatal_issue() -> void:
	var step = TileSetBuildStep.new()
	var context = ThemeBuildContext.new()
	context.theme_name = "test_theme"
	context.report = ThemeBuildReport.new()
	# theme_tile_assets is null
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()
	assert_object(context.tileset).is_null()


# ── Tile collection helpers ──────────────────────────────────────────

func test_collect_all_tiles_includes_background_platform_walls() -> void:
	var step = TileSetBuildStep.new()
	var assets = ThemeTileAssets.new()
	var platforms := TileAssetsPack.new()
	var platform_single: Array[String] = ["p1"]
	platforms.single = platform_single
	assets.platforms = platforms
	var walls := TileAssetsPack.new()
	var wall_single: Array[String] = ["w1"]
	walls.single = wall_single
	assets.walls = walls
	var background: Array[String] = ["bg1", "bg2"]
	assets.background = background
	
	# Use a reflected call to access the private method
	var result: Array = step._collect_all_tiles(assets)
	
	assert_bool(result is Array).is_true()
	var categories: Array[String] = []
	for tile_info: Dictionary in result:
		categories.append(tile_info["category"])
	assert_array(categories).contains_exactly(["background", "background", "platform", "walls"])


func test_collect_all_tiles_duplicate_names_added_once() -> void:
	var step = TileSetBuildStep.new()
	var assets = ThemeTileAssets.new()
	assets.platforms = TileAssetsPack.new()
	assets.walls = TileAssetsPack.new()
	# Add duplicate background variants
	var background: Array[String] = ["bg1", "bg1", "bg2"]
	assets.background = background
	
	var result: Array = step._collect_all_tiles(assets)
	
	# "bg1" should appear only once
	var bg_count := 0
	for tile_info: Dictionary in result:
		if tile_info["name"] == "background_bg1":
			bg_count += 1
	assert_int(bg_count).is_equal(1)


# ── Tile packing helpers ─────────────────────────────────────────────

func test_pack_to_tile_infos_maps_pack_fields() -> void:
	var step = TileSetBuildStep.new()
	var pack = TileAssetsPack.new()
	var single: Array[String] = ["s1"]
	var top: Array[String] = ["t1"]
	var full: Array[String] = ["f1"]
	pack.single = single
	pack.top = top
	pack.full = full
	
	var result: Array = step._pack_to_tile_infos(pack, "platform")
	
	assert_int(result.size()).is_equal(3)
	
	var names: Array[String] = []
	for info: Dictionary in result:
		names.append(info["name"])
	
	assert_bool(names.has("platform_single_s1")).is_true()
	assert_bool(names.has("platform_top_t1")).is_true()
	assert_bool(names.has("platform_full_f1")).is_true()


# ── Background from map ─────────────────────────────────────────────

func test_build_background_from_map_preserves_variant_order() -> void:
	var step = TileSetBuildStep.new()
	var tile_map: Dictionary = {}
	tile_map["background_varA"] = TileId.at_source(1, Vector2i.ZERO)
	tile_map["background_varB"] = TileId.at_source(2, Vector2i.ZERO)
	
	var variants: Array[String] = ["varA", "varB"]
	var result: Array[TileId] = step._build_background_from_map(variants, tile_map)
	
	assert_int(result.size()).is_equal(2)
	assert_int(result[0].source_id).is_equal(1)
	assert_int(result[1].source_id).is_equal(2)


# ── Map IDs with suffix ─────────────────────────────────────────────

func test_map_ids_with_suffix_returns_only_present_ids() -> void:
	var step = TileSetBuildStep.new()
	var tile_map: Dictionary = {}
	tile_map["platform_single_s1"] = TileId.at_source(1, Vector2i.ZERO)
	# platform_single_s2 not in map
	
	var variants: Array[String] = ["s1", "s2"]
	var result: Array[TileId] = step._map_ids_with_suffix(variants, tile_map, "platform", "single")
	
	assert_int(result.size()).is_equal(1)
	assert_int(result[0].source_id).is_equal(1)


# ── Tile size ────────────────────────────────────────────────────────

func test_tile_size_is_32() -> void:
	var step = TileSetBuildStep.new()
	assert_int(step.TILE_SIZE).is_equal(32)


# ── Full build against the default theme assets ──────────────────────

func _build_default_theme_context() -> ThemeBuildContext:
	var context := ThemeBuildContext.new()
	context.theme_name = "default"
	context.report = ThemeBuildReport.new()
	ThemeAssetsLoadStep.new().run(context)
	return context


func _collect_tile_ids(pack: TilePack) -> Array[TileId]:
	var result: Array[TileId] = []
	for field in TILE_PACK_FIELDS:
		var ids: Array = pack.get(field)
		result.append_array(ids)
	return result


func _assert_has_collision(tileset: TileSet, tile_id: TileId) -> void:
	var source := tileset.get_source(tile_id.source_id) as TileSetAtlasSource
	assert_object(source).is_not_null()
	var tile_data := source.get_tile_data(tile_id.atlas_coords, 0)
	assert_object(tile_data).is_not_null()
	assert_int(tile_data.get_collision_polygons_count(0)).is_equal(1)


func _assert_has_no_collision(tileset: TileSet, tile_id: TileId) -> void:
	var source := tileset.get_source(tile_id.source_id) as TileSetAtlasSource
	assert_object(source).is_not_null()
	var tile_data := source.get_tile_data(tile_id.atlas_coords, 0)
	assert_object(tile_data).is_not_null()
	assert_int(tile_data.get_collision_polygons_count(0)).is_zero()


func test_output_theme_info_references_generated_tileset_path() -> void:
	var context := _build_default_theme_context()
	assert_bool(context.report.has_fatal()).is_false()

	TileSetBuildStep.new().run(context)

	assert_bool(context.report.has_fatal()).is_false()
	assert_str(context.theme_info.tileset).is_equal(
		"res://resources/themes/default/default_tileset.tres"
	)


func test_platform_and_wall_sources_receive_solid_collision() -> void:
	var context := _build_default_theme_context()

	TileSetBuildStep.new().run(context)

	var platform_ids := _collect_tile_ids(context.theme_info.platforms)
	var wall_ids := _collect_tile_ids(context.theme_info.walls)
	assert_bool(platform_ids.is_empty()).is_false()
	assert_bool(wall_ids.is_empty()).is_false()

	for tile_id in platform_ids:
		_assert_has_collision(context.tileset, tile_id)
	for tile_id in wall_ids:
		_assert_has_collision(context.tileset, tile_id)


func test_background_sources_receive_no_collision() -> void:
	var context := _build_default_theme_context()

	TileSetBuildStep.new().run(context)

	assert_bool(context.theme_info.background.is_empty()).is_false()
	for tile_id in context.theme_info.background:
		_assert_has_no_collision(context.tileset, tile_id)
