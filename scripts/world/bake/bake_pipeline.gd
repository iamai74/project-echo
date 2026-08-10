class_name BakePipline
extends RefCounted

var _steps: Array[BakeStep] = []


func _init() -> void:
	var registry = _create_registry()
	var collector = _create_brush_collector()
	_steps = [
		CollectBrushesStep.new(collector),
		InitSemanticDataStep.new(),
		BakeSemanticLayerStep.new(registry)
	]


func _create_brush_collector() -> BrushCollector:
	var brush_collector = BrushCollector.new()
	return brush_collector


func _create_registry() -> BakeProcessorRegistry:
	var registry = BakeProcessorRegistry.new()
	registry.register(SemanticBrush.BrushType.FLOOR, PlatformBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.WALL, WallBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.BACKGROUND, BackgroundBakeProcessor.new())
	return registry
