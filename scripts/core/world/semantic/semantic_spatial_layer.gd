class_name SpatialLayer
extends RefCounted

enum SpatialType { FLOOR, WALL, BACKGROUND }

var _layers: Dictionary = {}


func add_cells(type: SpatialType, vector_array: Array[SemanticSpatialCell]) -> void:
	if !_layers.has(type):
		_layers[type] = Array[SemanticSpatialCell].new()
	_layers[type].append_array(vector_array)


func set_cells(type: SpatialType, vector_array: Array[SemanticSpatialCell]) -> void:
	_layers[type] = vector_array


func get_cells(type: SpatialType) -> Array[SemanticSpatialCell]:
	return _layers.get(type, Array[SemanticSpatialCell].new())
