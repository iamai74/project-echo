class_name ThemeAssetsLoadStep
extends BuildStep


const ASSETS_PATH := "res://assets/sprites/themes/{theme}/{theme}.json"

const KNOWN_TILE_TYPES := [
	"single_all",
	"single_top",
	"single_bottom",
	"single_left",
	"single_right",
	"single",
	"top_left",
	"top_right",
	"bottom_left",
	"bottom_right",
	"top",
	"bottom",
	"left",
	"right",
	"full",
]


func get_id() -> StringName:
	return &"theme_assets_load"


func get_display_name() -> String:
	return "Load theme assets"


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	var path := ASSETS_PATH.format({theme: context.theme_name})

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ThemeAssetsLoadStep: Cannot open ", path)
		return context

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("ThemeAssetsLoadStep: JSON parse error in ", path, " at line ", json.get_error_line())
		return context

	var data := json.get_data()
	if data == null or not data.has("meta"):
		push_error("ThemeAssetsLoadStep: Invalid theme JSON structure in ", path)
		return context

	var slices: Array = data["meta"].get("slices", [])

	var assets := ThemeTileAssets.new()
	assets.platforms = TilePack.new()
	assets.walls = TilePack.new()
	assets.background = []

	for slice in slices:
		var name: String = slice.get("name", "")
		var parsed := _parse_slice_name(name)
		if parsed == null:
			continue

		var category: String = parsed["category"]
		var variant: String = parsed["variant"]

		if category == "background":
			assets.background.append(variant)
		elif category == "platform":
			_assign_to_pack(assets.platforms, parsed["tile_type"], variant)
		elif category == "walls":
			_assign_to_pack(assets.walls, parsed["tile_type"], variant)

	context.theme_tile_assets = assets

	return context


func _parse_slice_name(name: String) -> Dictionary:
	var variant := _extract_variant(name)
	if variant == "":
		return null

	var name_without_variant := name.substr(0, name.length() - variant.length() - 1)

	var category := _extract_category(name_without_variant)
	if category == "":
		return null

	var remainder := name_without_variant.substr(category.length() + 1)
	var tile_type := _match_tile_type(remainder)

	if tile_type == "":
		return null

	return {"category": category, "tile_type": tile_type, "variant": variant}


func _extract_variant(name: String) -> String:
	var result := RegEx.create_from_string(r"_[0-9]+(?=[^_]*$)")
	var match := result.search(name)
	if match:
		return match.get_string().substr(1)
	return ""


func _extract_category(name: String) -> String:
	for category in ["background", "platform", "walls"]:
		if name.begins_with(category):
			return category
	return ""


func _match_tile_type(remainder: String) -> String:
	for tile_type in KNOWN_TILE_TYPES:
		if remainder == tile_type:
			return tile_type
	return ""


func _assign_to_pack(pack: TilePack, tile_type: String, variant: String) -> void:
	match tile_type:
		"single", "single_all":
			pack.single.append(variant)
		"single_top":
			pack.single_top.append(variant)
		"single_bottom":
			pack.single_bottom.append(variant)
		"single_left":
			pack.single_left.append(variant)
		"single_right":
			pack.single_right.append(variant)
		"top":
			pack.top.append(variant)
		"bottom":
			pack.bottom.append(variant)
		"left":
			pack.left.append(variant)
		"right":
			pack.right.append(variant)
		"full":
			pack.full.append(variant)
		"top_left":
			pack.top_left.append(variant)
		"top_right":
			pack.top_right.append(variant)
		"bottom_left":
			pack.bottom_left.append(variant)
		"bottom_right":
			pack.bottom_right.append(variant)
