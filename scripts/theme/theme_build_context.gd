class_name ThemeBuildContext
extends RefCounted

const RESOURCES_PATH := "res://resources/themes/{theme}/"

var theme_name: String
var theme_tile_assets: ThemeTileAssets
var theme_info: ThemeInfo
var tileset: TileSet
var report: ThemeBuildReport


func get_resource_dir() -> String:
	return RESOURCES_PATH.format({"theme": theme_name})


func get_resource_prefix() -> String:
	return get_resource_dir() + theme_name
