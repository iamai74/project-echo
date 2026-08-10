class_name BakeProcessorRegistry
extends RefCounted

var _processors: Dictionary[SemanticBrush.BrushType, BakeProcessor]


func register(brush_type: SemanticBrush.BrushType, processor: BakeProcessor) -> void:
	_processors[brush_type] = processor


func get_types() -> Array[SemanticBrush.BrushType]:
	return _processors.keys()


func get_processor(brush_type: SemanticBrush.BrushType) -> BakeProcessor:
	return _processors.get(brush_type)
