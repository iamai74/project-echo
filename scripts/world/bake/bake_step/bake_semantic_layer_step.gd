class_name BakeSemanticLayerStep
extends BakeStep

var _registry: BakeProcessorRegistry
var _current_context: RoomBakeContext


func _init(registry: BakeProcessorRegistry) -> void:
	_registry = registry


func get_id() -> StringName:
	return &"bake_semantic_layer"


func get_display_name() -> String:
	return "BakeSemanticLayerStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	_current_context = context
	var registry_brush_types = _registry.get_types()
	for type in registry_brush_types:
		var processor = _registry.get_processor(type)
		var brushes = context.brushes.get_brushes(type)
		processor.issue_found.connect(_on_processor_issue)
		processor.execute(brushes, context.semantic_data)
		processor.issue_found.disconnect(_on_processor_issue)
	return context


func _on_processor_issue(issue: BakeIssue) -> void:
	_current_context.report.add_issue(issue)
