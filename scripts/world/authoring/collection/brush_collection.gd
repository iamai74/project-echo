class_name BrushCollection
extends RefCounted

var _brushes: Dictionary = {}
var _all_brushes: Array[SemanticBrush] = []


func add_brush(brush: SemanticBrush) -> void:
	_all_brushes.append(brush)
	var type := brush.get_brush_type()
	if type == SemanticBrush.BrushType.UNKNOWN:
		return
	if !_brushes.has(type):
		var empty_brushes: Array[SemanticBrush] = []
		_brushes[type] = empty_brushes
	_brushes[type].append(brush)


func get_brushes(type: SemanticBrush.BrushType) -> Array[SemanticBrush]:
	var empty_brushes: Array[SemanticBrush] = []
	return _brushes.get(type, empty_brushes)


func get_all_brushes() -> Array[SemanticBrush]:
	var all_brushes: Array[SemanticBrush] = []
	all_brushes.assign(_all_brushes)
	return all_brushes
