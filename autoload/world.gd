@tool
extends Node

var _settings: WorldSettings = preload("res://resources/world/world_settings.tres")

var settings: WorldSettings:
	get:
		return _settings
