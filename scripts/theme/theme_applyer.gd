class_name ThemeApplyer
extends RefCounted


func apply(room_node: Node, theme: ThemeInfo, room_data: RoomData) -> void:
	var tile_map := _find_tile_map(room_node)
	if tile_map == null:
		push_error("ThemeApplyer: TileMapLayer not found")
		return

	var tileset := load(theme.tileset) as TileSet
	if tileset == null:
		push_error("ThemeApplyer: Cannot load TileSet from ", theme.tileset)
		return

	tile_map.tile_set = tileset

	_apply_background(tile_map, theme.background, room_data.background)
	_apply_platforms(tile_map, theme.platforms, room_data.platforms)
	_apply_walls(tile_map, theme.walls, room_data.walls)


func _find_tile_map(room_node: Node) -> TileMapLayer:
	var semantic := room_node.get_node_or_null("Semantic")
	if semantic == null:
		return null

	var tiles := semantic.get_node_or_null("Tiles")
	if tiles is TileMapLayer:
		return tiles as TileMapLayer

	return null


func _apply_background(
	tile_map: TileMapLayer, background_ids: Array[TileId], background_cells: Array[BackgroundCell]
) -> void:
	for cell in background_cells:
		var idx := _index(cell.position.y, background_ids)
		if idx < 0:
			continue
		var tile_id: TileId = background_ids[idx]
		_place(tile_map, tile_id, cell.position)


func _apply_platforms(tile_map: TileMapLayer, pack: TilePack, cells: Array[SemanticCell]) -> void:
	for cell in cells:
		var shape_name: String = CellShape.Value.keys()[cell.shape]
		var corner_name: String = CellCorner.Value.keys()[cell.corners]

		var key := _select_key(shape_name, corner_name)
		var ids := _get_pack_array(pack, key)

		var idx := _index(cell.position.y, ids)
		if idx < 0:
			continue
		var tile_id: TileId = ids[idx]
		_place(tile_map, tile_id, cell.position)


func _apply_walls(tile_map: TileMapLayer, pack: TilePack, cells: Array[SemanticCell]) -> void:
	for cell in cells:
		var shape_name: String = CellShape.Value.keys()[cell.shape]
		var corner_name: String = CellCorner.Value.keys()[cell.corners]

		var key := _select_key(shape_name, corner_name)
		var ids := _get_pack_array(pack, key)

		var idx := _index(cell.position.y, ids)
		if idx < 0:
			continue
		var tile_id: TileId = ids[idx]
		_place(tile_map, tile_id, cell.position)


func _select_key(shape_name: String, corner_name: String) -> String:
	if shape_name == "FULL":
		return "full"

	if shape_name == "SINGLE":
		if corner_name == "ALL":
			return "single_all"
		if corner_name == "NO":
			return "single"
		return "single_%s" % corner_name.to_lower()

	if corner_name == "NO":
		return shape_name.to_lower()

	return corner_name.to_lower()


func _get_pack_array(pack: TilePack, key: String) -> Array[TileId]:
	match key:
		"single":
			return pack.single
		"single_all":
			return pack.single_all
		"single_top":
			return pack.single_top
		"single_bottom":
			return pack.single_bottom
		"single_left":
			return pack.single_left
		"single_right":
			return pack.single_right
		"top":
			return pack.top
		"bottom":
			return pack.bottom
		"left":
			return pack.left
		"right":
			return pack.right
		"full":
			return pack.full
		"top_left":
			return pack.top_left
		"top_right":
			return pack.top_right
		"bottom_left":
			return pack.bottom_left
		"bottom_right":
			return pack.bottom_right

	return []


func _index(_position_y: int, array: Array) -> int:
	if array.is_empty():
		return -1
	return randi() % array.size()


func _place(tile_map: TileMapLayer, tile_id: TileId, cell_pos: Vector2i) -> void:
	tile_map.set_cell(cell_pos, tile_id.source_id, tile_id.atlas_coords)
