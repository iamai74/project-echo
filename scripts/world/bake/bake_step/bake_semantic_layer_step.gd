class_name BakeSemanticLayerStep
extends BakeStep

var _registry: BakeProcessorRegistry


func _init(registry: BakeProcessorRegistry) -> void:
	_registry = registry


func get_id() -> StringName:
	return &"bake_semantic_layer"


func get_display_name() -> String:
	return "BakeSemanticLayerStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	var registry_brush_types = _registry.get_types()
	for type in registry_brush_types:
		var processor = _registry.get_processor(type)
		var brushes = context.brushes.get_brushes(type)
		processor.execute(brushes, context.semantic_data)
	return context
