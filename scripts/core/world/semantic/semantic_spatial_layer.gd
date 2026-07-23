class_name SpatialLayer
extends RefCounted

enum SpatialType { FLOOR, WALL, BACKGROUND }

var _layers: Dictionary = {}


func add_cells(type: SpatialType, vector_array: PackedVector2Array) -> void:
	if !_layers.has(type):
		_layers[type] = PackedVector2Array()
	_layers[type].append_array(vector_array)


func set_cells(type: SpatialType, vector_array: PackedVector2Array) -> void:
	_layers[type] = vector_array


func get_cells(type: SpatialType) -> PackedVector2Array:
	return _layers.get(type, PackedVector2Array())
