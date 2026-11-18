class_name ThemeBuildContext
extends RefCounted

var resources_path: String = "res://resources/themes/{theme}/"

var theme_name: String
var theme_tile_assets: ThemeTileAssets
var theme_info: ThemeInfo
var tileset: TileSet
var report: ThemeBuildReport
var tile_size: int = 0


func get_resource_dir() -> String:
	return resources_path.format({"theme": theme_name})


func get_resource_prefix() -> String:
	return get_resource_dir() + theme_name
