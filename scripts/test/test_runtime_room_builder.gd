## RuntimeRoomBuilder unit tests.
## Covers: node tree structure, Semantic child, Tiles TileMapLayer child.
extends GdUnitTestSuite


func test_build_creates_node2d() -> void:
	var room_data = RoomData.new()
	var builder = RuntimeRoomBuilder.new()
	var result = auto_free(builder.build(room_data))

	assert_object(result).is_not_null()
	assert_bool(result is Node2D).is_true()


func test_build_names_node_runtime_room() -> void:
	var room_data = RoomData.new()
	var builder = RuntimeRoomBuilder.new()
	var result = auto_free(builder.build(room_data))

	assert_str(result.name).is_equal("RuntimeRoom")


func test_build_has_semantic_child() -> void:
	var room_data = RoomData.new()
	var builder = RuntimeRoomBuilder.new()
	var result = auto_free(builder.build(room_data))

	var semantic = result.get_node_or_null("Semantic")
	assert_object(semantic).is_not_null()
	assert_bool(semantic is Node2D).is_true()


func test_build_semantic_has_tiles_child() -> void:
	var room_data = RoomData.new()
	var builder = RuntimeRoomBuilder.new()
	var result = auto_free(builder.build(room_data))

	var semantic = result.get_node_or_null("Semantic")
	var tiles = semantic.get_node_or_null("Tiles")
	assert_object(tiles).is_not_null()
	assert_bool(tiles is TileMapLayer).is_true()


func test_build_nodes_have_owner_set() -> void:
	var room_data = RoomData.new()
	var builder = RuntimeRoomBuilder.new()
	var result = auto_free(builder.build(room_data))

	var semantic = result.get_node_or_null("Semantic")
	var tiles = semantic.get_node_or_null("Tiles")
	assert_bool(semantic.owner == result).is_true()
	assert_bool(tiles.owner == result).is_true()
