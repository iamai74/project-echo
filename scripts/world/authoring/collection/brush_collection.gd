class_name BrushCollection
extends RefCounted

var _brushes: Dictionary = {}


func add_brush(brush: SemanticBrush) -> void:
	var type = brush.get_brush_type()
	if type == SemanticBrush.BrushType.UNKNOWN:
		return
	if !_brushes.has(type):
		var empty_brushes: Array[SemanticBrush] = []
		_brushes[type] = empty_brushes
	_brushes[type].append(brush)


func get_brushes(type: SemanticBrush.BrushType) -> Array[SemanticBrush]:
	var empty_brushes: Array[SemanticBrush] = []
	return _brushes.get(type, empty_brushes)
