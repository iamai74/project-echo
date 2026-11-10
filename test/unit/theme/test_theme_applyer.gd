## ThemeApplyer unit tests.
## Covers: _select_key mapping, error path when TileMapLayer missing,
## _get_pack_array mapping, and basic apply structure.
extends GdUnitTestSuite


var applyer: ThemeApplyer


func before_test() -> void:
	applyer = auto_free(ThemeApplyer.new())


# --- _select_key: shape/corner combinations ---

func test_select_key_parameters(shape: String, corner: String, expected: String, _test_parameters := [
	["FULL", "NO", "full"],
	["FULL", "top_left", "full"],
	["SINGLE", "NO", "single"],
	["SINGLE", "ALL", "single_all"],
	["SINGLE", "TOP", "single_top"],
	["SINGLE", "BOTTOM", "single_bottom"],
	["SINGLE", "LEFT", "single_left"],
	["SINGLE", "RIGHT", "single_right"],
	["TOP", "NO", "top"],
	["RIGHT", "NO", "right"],
	["TOP", "LEFT", "left"],
	["LEFT", "BOTTOM", "bottom"]
]) -> void:
	var key = applyer._select_key(shape, corner)
	assert_str(key).is_equal(expected)


# --- _get_pack_array mapping ---

func test_get_pack_array_elements(key: String, expected_elements: Array[Vector2i], _test_parameters := [
		["single", [Vector2i.ZERO]],
		["single_all", [Vector2i.ZERO]],
		["single_top", [Vector2i.ZERO]],
		["single_bottom", [Vector2i.ZERO]],
		["single_left", [Vector2i.ZERO]],
		["single_right", [Vector2i.ZERO]],
		["top", [Vector2i.ZERO]],
		["bottom", [Vector2i.ZERO]],
		["left", [Vector2i.ZERO]],
		["right", [Vector2i.ZERO]],
		["full", [Vector2i.ZERO]],
		["top_left", [Vector2i.ZERO]],
		["top_right", [Vector2i.ZERO]],
		["bottom_left", [Vector2i.ZERO]],
		["bottom_right", [Vector2i.ZERO]],
		["nonexistent", []]
	]
) -> void:
	var pack = TilePack.new()
	var target: Array[TileId] = []
	match key:
		"single":
			target = pack.single
		"single_all":
			target = pack.single_all
		"single_top":
			target = pack.single_top
		"single_bottom":
			target = pack.single_bottom
		"single_left":
			target = pack.single_left
		"single_right":
			target = pack.single_right
		"top":
			target = pack.top
		"bottom":
			target = pack.bottom
		"left":
			target = pack.left
		"right":
			target = pack.right
		"full":
			target = pack.full
		"top_left":
			target = pack.top_left
		"top_right":
			target = pack.top_right
		"bottom_left":
			target = pack.bottom_left
		"bottom_right":
			target = pack.bottom_right
	target.append(TileId.new(0, Vector2i.ZERO))

	var result = applyer._get_pack_array(pack, key)
	assert_int(result.size()).is_equal(expected_elements.size())
	for i in range(result.size()):
		assert_vector(result[i].atlas_coords).is_equal(expected_elements[i])


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
