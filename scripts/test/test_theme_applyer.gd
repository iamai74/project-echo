## ThemeApplyer unit tests.
## Covers: _select_key mapping, error path when TileMapLayer missing,
## _get_pack_array mapping, and basic apply structure.
extends GdUnitTestSuite


var applyer: ThemeApplyer


func before_test() -> void:
	applyer = auto_free(ThemeApplyer.new())


# --- _select_key: shape/corner combinations ---

func test_select_key_full_shape_returns_full() -> void:
	var key = applyer._select_key("FULL", "NO")
	assert_str(key).is_equal("full")


func test_select_key_full_shape_ignores_corner() -> void:
	var key = applyer._select_key("FULL", "TOP_LEFT")
	assert_str(key).is_equal("full")


func test_select_key_single_no_corner_returns_single() -> void:
	var key = applyer._select_key("SINGLE", "NO")
	assert_str(key).is_equal("single")


func test_select_key_single_all_corner_returns_single_all() -> void:
	var key = applyer._select_key("SINGLE", "ALL")
	assert_str(key).is_equal("single_all")


func test_select_key_single_top_corner_returns_single_top() -> void:
	var key = applyer._select_key("SINGLE", "TOP")
	assert_str(key).is_equal("single_top")


func test_select_key_single_bottom_corner_returns_single_bottom() -> void:
	var key = applyer._select_key("SINGLE", "BOTTOM")
	assert_str(key).is_equal("single_bottom")


func test_select_key_single_left_corner_returns_single_left() -> void:
	var key = applyer._select_key("SINGLE", "LEFT")
	assert_str(key).is_equal("single_left")


func test_select_key_single_right_corner_returns_single_right() -> void:
	var key = applyer._select_key("SINGLE", "RIGHT")
	assert_str(key).is_equal("single_right")


func test_select_key_shape_no_corner_returns_shape_lower() -> void:
	var key = applyer._select_key("TOP", "NO")
	assert_str(key).is_equal("top")


func test_select_key_shape_no_corner_returns_right_lower() -> void:
	var key = applyer._select_key("RIGHT", "NO")
	assert_str(key).is_equal("right")


func test_select_key_shape_with_corner_returns_corner_lower() -> void:
	var key = applyer._select_key("TOP", "LEFT")
	assert_str(key).is_equal("left")


func test_select_key_shape_with_corner_returns_corner_lower_2() -> void:
	var key = applyer._select_key("LEFT", "BOTTOM")
	assert_str(key).is_equal("bottom")


# --- _get_pack_array mapping ---

func test_get_pack_array_single_key_returns_single() -> void:
	var pack = TilePack.new()
	pack.single.append(TileId.new(0, Vector2i.ZERO))
	var result = applyer._get_pack_array(pack, "single")
	assert_int(result.size()).is_equal(1)


func test_get_pack_array_full_key_returns_full() -> void:
	var pack = TilePack.new()
	pack.full.append(TileId.new(0, Vector2i.ZERO))
	var result = applyer._get_pack_array(pack, "full")
	assert_int(result.size()).is_equal(1)


func test_get_pack_array_top_left_key_returns_top_left() -> void:
	var pack = TilePack.new()
	pack.top_left.append(TileId.new(0, Vector2i.ZERO))
	var result = applyer._get_pack_array(pack, "top_left")
	assert_int(result.size()).is_equal(1)


func test_get_pack_array_unknown_key_returns_empty() -> void:
	var pack = TilePack.new()
	var result = applyer._get_pack_array(pack, "nonexistent")
	assert_int(result.size()).is_zero()


func test_get_pack_array_single_top_returns_correct_array() -> void:
	var pack = TilePack.new()
	pack.single_top.append(TileId.new(1, Vector2i(32, 0)))
	var result = applyer._get_pack_array(pack, "single_top")
	assert_int(result.size()).is_equal(1)
	assert_int(result[0].source_id).is_equal(1)


# --- Error paths ---

func test_apply_missing_tilemap_layer_pushes_error() -> void:
	var room_node = auto_free(Node2D.new())
	room_node.name = "Room"

	var theme = ThemeInfo.new()

	var room_data = RoomData.new()

	# Without a Semantic/Tiles child, _find_tile_map returns null.
	# The apply method pushes an error and returns early.
	assert_error(func() -> void: applyer.apply(room_node, theme, room_data)) \
		.is_push_error("ThemeApplyer: TileMapLayer not found")
