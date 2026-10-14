class_name TilePack
extends Resource

# Single platforms/walls
@export var single: Array[TileId]
@export var single_all: Array[TileId]
@export var single_top: Array[TileId]
@export var single_bottom: Array[TileId]
@export var single_left: Array[TileId]
@export var single_right: Array[TileId]
# Other by side
@export var top: Array[TileId]
@export var bottom: Array[TileId]
@export var left: Array[TileId]
@export var right: Array[TileId]
@export var full: Array[TileId]
# Other corners
@export var top_left: Array[TileId]
@export var top_right: Array[TileId]
@export var bottom_left: Array[TileId]
@export var bottom_right: Array[TileId]
