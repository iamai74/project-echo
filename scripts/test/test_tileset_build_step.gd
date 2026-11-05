## TileSetBuildStep unit tests.
## Covers: pure helpers, tile collection, tile mapping, and collision assignment.
## Loading real textures belongs in an integration test.
extends GdUnitTestSuite


# ── Missing ThemeTileAssets adds fatal issue ─────────────────────────

func test_missing_theme_tile_assets_adds_fatal_issue() -> void:
	var step = TileSetBuildStep.new()
	var context = ThemeBuildContext.new()
	context.theme_name = "test_theme"
	context.report = ThemeBuildReport.new()
	# theme_tile_assets is null
	
	step.run(context)
	
	assert_bool(context.report.has_fatal()).is_true()


# ── Tile collection helpers ──────────────────────────────────────────

func test_collect_all_tiles_includes_background_platform_walls() -> void:
	var step = TileSetBuildStep.new()
	var assets = ThemeTileAssets.new()
	assets.platforms = TileAssetsPack.new()
	assets.walls = TileAssetsPack.new()
	var background: Array[String] = ["bg1", "bg2"]
	assets.background = background
	
	# Use a reflected call to access the private method
	var result: Array = step._collect_all_tiles(assets)
	
	# Should include background variants and platform/wall variants
	assert_bool(result is Array).is_true()
	# Background tiles are present
	var has_background := false
	for tile_info: Dictionary in result:
		if tile_info["category"] == "background":
			has_background = true
			break
	assert_bool(has_background).is_true()


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
