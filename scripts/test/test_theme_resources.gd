## Theme resource unit tests.
## Covers: TileAssetsPack defaults, ThemeTileAssets defaults, TileId.at_source.
extends GdUnitTestSuite


# ── TileAssetsPack ──────────────────────────────────────────────────

func test_tile_assets_pack_defaults_empty_arrays() -> void:
	var pack = TileAssetsPack.new()
	
	assert_int(pack.single.size()).is_zero()
	assert_int(pack.single_all.size()).is_zero()
	assert_int(pack.single_top.size()).is_zero()
	assert_int(pack.single_bottom.size()).is_zero()
	assert_int(pack.single_left.size()).is_zero()
	assert_int(pack.single_right.size()).is_zero()
	assert_int(pack.top.size()).is_zero()
	assert_int(pack.bottom.size()).is_zero()
	assert_int(pack.left.size()).is_zero()
	assert_int(pack.right.size()).is_zero()
	assert_int(pack.full.size()).is_zero()
	assert_int(pack.top_left.size()).is_zero()
	assert_int(pack.top_right.size()).is_zero()
	assert_int(pack.bottom_left.size()).is_zero()
	assert_int(pack.bottom_right.size()).is_zero()


# ── ThemeTileAssets ─────────────────────────────────────────────────

func test_theme_tile_assets_defaults_safe() -> void:
	var assets = ThemeTileAssets.new()
	
	assert_object(assets.platforms).is_null()
	assert_object(assets.walls).is_null()
	assert_int(assets.background.size()).is_zero()


# ── TileId ──────────────────────────────────────────────────────────

func test_tile_id_at_source_copies_values() -> void:
	var tile_id = TileId.at_source(5, Vector2i(3, 4))
	
	assert_int(tile_id.source_id).is_equal(5)
	assert_vector(tile_id.atlas_coords).is_equal(Vector2i(3, 4))


func test_tile_id_defaults() -> void:
	var tile_id = TileId.new()
	
	assert_int(tile_id.source_id).is_zero()
	assert_vector(tile_id.atlas_coords).is_equal(Vector2i.ZERO)
