class_name CollectBrushesStep
extends BakeStep

var _collector: BrushCollector


func _init(collector: BrushCollector) -> void:
	_collector = collector


func get_id() -> StringName:
	return &"collect_brushes"


func get_display_name() -> String:
	return "CollectBrushesStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	context.brushes = _collector.collect(context.room)
	if context.room is RoomAuthoring:
		context.room_bounds = (context.room as RoomAuthoring).room_bounds
	else:
		context.room_bounds = Rect2i()
	return context
