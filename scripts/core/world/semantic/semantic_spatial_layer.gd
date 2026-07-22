class_name SpatialLayer
extends RefCounted

var _layers: Dictionary = {}

enum SpatialType {
	FLOOR,
	WALL,
	BACKGROUND
}

func add_cells(type: SpatialType, vectorArray: PackedVector2Array) -> void:
	if !_layers.has(type):
		_layers[type] = PackedVector2Array()
	_layers[type].append_array(vectorArray)

func set_cells(type: SpatialType, vectorArray: PackedVector2Array) -> void:
	_layers[type] = vectorArray

func get_cells(type: SpatialType) -> PackedVector2Array:
	return _layers.get(type, PackedVector2Array())
