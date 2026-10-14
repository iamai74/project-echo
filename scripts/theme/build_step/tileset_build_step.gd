class_name TileSetBuildStep
extends BuildStep

const TILE_SIZE := 32
const PLATFORM_COLLISION_HEIGHT := 4


func get_id() -> StringName:
	return &"tileset_build"


func get_display_name() -> String:
	return "Build TileSet"


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	if context.theme_tile_assets == null:
		context.report.add_error(
			ThemeBuildIssue.new(
				ThemeBuildIssue.IssueType.UNKNOWN,
				ThemeBuildIssue.Severity.FATAL,
				"ThemeTileAssets not loaded, cannot build TileSet"
			)
		)
		return context

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var theme_dir := "res://assets/sprites/themes/%s/" % context.theme_name

	var tile_map := _build_tile_map(context.theme_tile_assets, tileset, theme_dir, context.report)

	if context.report.has_fatal():
		return context

	context.tileset = tileset

	var theme_info := ThemeInfo.new()
	theme_info.tileset = ""
	theme_info.platforms = _build_tile_pack_from_maps(
		context.theme_tile_assets.platforms, tile_map, "platform"
	)
	theme_info.walls = _build_tile_pack_from_maps(
		context.theme_tile_assets.walls, tile_map, "walls"
	)
	theme_info.background = _build_background_from_map(
		context.theme_tile_assets.background, tile_map
	)

	context.theme_info = theme_info

	return context


func _build_tile_map(
	assets: ThemeTileAssets,
	tileset: TileSet,
	theme_dir: String,
	report: ThemeBuildReport
) -> Dictionary:

	tileset.add_physics_layer()

	var tile_map: Dictionary = {}
	var all_tiles := _collect_all_tiles(assets)

	for tile_info: Dictionary in all_tiles:
		var tile_name := tile_info["name"] as String
		var texture := _load_texture(theme_dir + tile_name + ".png", report)
		if texture == null:
			continue

		var source := _create_tile_source(texture)
		var source_id := tileset.add_source(source)
		if source_id == -1:
			report.add_error(
				ThemeBuildIssue.new(
					ThemeBuildIssue.IssueType.UNKNOWN,
					ThemeBuildIssue.Severity.FATAL,
					"Failed to add tile source for: %s" % tile_name
				)
			)
			return {}

		source.create_tile(Vector2i.ZERO, Vector2i.ONE)

		var tile_id_val := TileId.at_source(source_id, Vector2i.ZERO)
		tile_map[tile_name] = tile_id_val

		var category := tile_info["category"] as String
		if category == "platform":
			_add_platform_collision(source, Vector2i.ZERO)
		elif category == "walls":
			_add_wall_collision(source, Vector2i.ZERO)

	return tile_map


func _collect_all_tiles(assets: ThemeTileAssets) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var result: Array[Dictionary] = []

	for bg_variant in assets.background:
		var name := "background_%s" % bg_variant
		_add_if_new(result, seen, name, "background")

	for tile_info: Dictionary in _pack_to_tile_infos(assets.platforms, "platform"):
		_add_if_new(result, seen, tile_info["name"], tile_info["category"])

	for tile_info: Dictionary in _pack_to_tile_infos(assets.walls, "walls"):
		_add_if_new(result, seen, tile_info["name"], tile_info["category"])

	return result


func _pack_to_tile_infos(pack: TileAssetsPack, category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var fields := [
		{"array_name": "single", "tile_type": "single"},
		{"array_name": "single_all", "tile_type": "single_all"},
		{"array_name": "single_top", "tile_type": "single_top"},
		{"array_name": "single_bottom", "tile_type": "single_bottom"},
		{"array_name": "single_left", "tile_type": "single_left"},
		{"array_name": "single_right", "tile_type": "single_right"},
		{"array_name": "top", "tile_type": "top"},
		{"array_name": "bottom", "tile_type": "bottom"},
		{"array_name": "left", "tile_type": "left"},
		{"array_name": "right", "tile_type": "right"},
		{"array_name": "full", "tile_type": "full"},
		{"array_name": "top_left", "tile_type": "top_left"},
		{"array_name": "top_right", "tile_type": "top_right"},
		{"array_name": "bottom_left", "tile_type": "bottom_left"},
		{"array_name": "bottom_right", "tile_type": "bottom_right"},
	]

	for field in fields:
		var arr := _get_array_by_name(pack, field.array_name)
		for variant in arr:
			var name := "%s_%s_%s" % [category, field.tile_type, variant]
			result.append({"name": name, "category": category})

	return result


func _get_array_by_name(pack: TileAssetsPack, field_name: String) -> Array[String]:
	var maps: Dictionary = {
		"single": pack.single,
		"single_all": pack.single_all,
		"single_top": pack.single_top,
		"single_bottom": pack.single_bottom,
		"single_left": pack.single_left,
		"single_right": pack.single_right,
		"top": pack.top,
		"bottom": pack.bottom,
		"left": pack.left,
		"right": pack.right,
		"full": pack.full,
		"top_left": pack.top_left,
		"top_right": pack.top_right,
		"bottom_left": pack.bottom_left,
		"bottom_right": pack.bottom_right,
	}
	if field_name in maps:
		return maps[field_name]
	return []


func _add_if_new(
	result: Array[Dictionary],
	seen: Dictionary,
	name: String,
	category: String
) -> void:
	if name in seen:
		return
	seen[name] = true
	result.append({"name": name, "category": category})


func _load_texture(path: String, report: ThemeBuildReport) -> Texture2D:
	var texture := load(path)
	if texture == null or not texture is Texture2D:
		report.add_error(
			ThemeBuildIssue.new(
				ThemeBuildIssue.IssueType.FILE_NOT_FOUND,
				ThemeBuildIssue.Severity.FATAL,
				"Cannot load texture: %s" % path
			)
		)
		return null
	return texture as Texture2D


func _create_tile_source(texture: Texture2D) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	return source


func _add_platform_collision(source: TileSetAtlasSource, atlas_coords: Vector2i) -> void:
	var tile_data := source.get_tile_data(atlas_coords, 0)
	if tile_data == null:
		return
	var half := TILE_SIZE / 2.0
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, -half + PLATFORM_COLLISION_HEIGHT),
		Vector2(-half, -half + PLATFORM_COLLISION_HEIGHT),
	]))


func _add_wall_collision(source: TileSetAtlasSource, atlas_coords: Vector2i) -> void:
	var tile_data := source.get_tile_data(atlas_coords, 0)
	if tile_data == null:
		return
	var half := TILE_SIZE / 2.0
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	]))


func _build_tile_pack_from_maps(
	pack: TileAssetsPack, tile_map: Dictionary, category: String
) -> TilePack:
	var result := TilePack.new()

	result.single = _map_ids_with_suffix(pack.single, tile_map, category, "single")
	result.single_all = _map_ids_with_suffix(pack.single_all, tile_map, category, "single_all")
	result.single_top = _map_ids_with_suffix(pack.single_top, tile_map, category, "single_top")
	result.single_bottom = _map_ids_with_suffix(pack.single_bottom, tile_map, category, "single_bottom")
	result.single_left = _map_ids_with_suffix(pack.single_left, tile_map, category, "single_left")
	result.single_right = _map_ids_with_suffix(pack.single_right, tile_map, category, "single_right")
	result.top = _map_ids_with_suffix(pack.top, tile_map, category, "top")
	result.bottom = _map_ids_with_suffix(pack.bottom, tile_map, category, "bottom")
	result.left = _map_ids_with_suffix(pack.left, tile_map, category, "left")
	result.right = _map_ids_with_suffix(pack.right, tile_map, category, "right")
	result.full = _map_ids_with_suffix(pack.full, tile_map, category, "full")
	result.top_left = _map_ids_with_suffix(pack.top_left, tile_map, category, "top_left")
	result.top_right = _map_ids_with_suffix(pack.top_right, tile_map, category, "top_right")
	result.bottom_left = _map_ids_with_suffix(pack.bottom_left, tile_map, category, "bottom_left")
	result.bottom_right = _map_ids_with_suffix(pack.bottom_right, tile_map, category, "bottom_right")

	return result


func _build_background_from_map(
	variants: Array[String], tile_map: Dictionary
) -> Array[TileId]:
	var result: Array[TileId] = []
	for variant in variants:
		var name := "background_%s" % variant
		if tile_map.has(name):
			result.append(tile_map[name])
	return result


func _map_ids_with_suffix(
	variants: Array[String], tile_map: Dictionary, category: String, tile_type: String
) -> Array[TileId]:
	var result: Array[TileId] = []
	for variant in variants:
		var name := "%s_%s_%s" % [category, tile_type, variant]
		if tile_map.has(name):
			result.append(tile_map[name])
	return result
