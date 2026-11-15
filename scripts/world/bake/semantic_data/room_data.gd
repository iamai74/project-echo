class_name RoomData
extends Resource

@export var version: int = 2
@export var room_bounds: Rect2i
@export var geometry_bounds: Rect2i

@export var platforms: Array[SemanticCell]
@export var walls: Array[SemanticCell]
@export var background: Array[BackgroundCell]

@export var markers: Array[MarkerData]
@export var connections: Array[ConnectionData]


func _set(property: StringName, value: Variant) -> bool:
	if property == &"bounds":
		if not geometry_bounds.has_area():
			geometry_bounds = value
		version = 1
		return true
	return false
