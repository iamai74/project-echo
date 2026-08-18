class_name SpatialLayer
extends RefCounted

enum SpatialType { FLOOR, WALL, BACKGROUND }

var _layers: Dictionary = {}


func add_cells(type: SpatialType, vector_array: Array[SemanticSpatialCell]) -> void:
	if !_layers.has(type):
		var empty_cells: Array[SemanticSpatialCell] = []
		_layers[type] = empty_cells
	_layers[type].append_array(vector_array)


func add_cell(type: SpatialType, new_cell: SemanticSpatialCell) -> bool:
	if !_layers.has(type):
		var empty_cells: Array[SemanticSpatialCell] = []
		_layers[type] = empty_cells
	var current_cells = _layers[type] as Array[SemanticSpatialCell]
	for cell in current_cells:
		if cell.cell == new_cell.cell:
			return false
	_layers[type].append(new_cell)
	return true


func set_cells(type: SpatialType, vector_array: Array[SemanticSpatialCell]) -> void:
	_layers[type] = vector_array


func get_cells(type: SpatialType) -> Array[SemanticSpatialCell]:
	var empty_cells: Array[SemanticSpatialCell] = []
	return _layers.get(type, empty_cells)
