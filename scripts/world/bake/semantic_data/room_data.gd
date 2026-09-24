class_name RoomData
extends Resource

@export var version: int = 1
@export var bounds: Rect2i

@export var platforms: Array[SemanticCell]
@export var walls: Array[SemanticCell]
@export var background: Array[BackgroundCell]

@export var connections: Array[ConnectionData]
