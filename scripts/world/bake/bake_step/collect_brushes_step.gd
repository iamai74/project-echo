class_name CollectBrushesStep
extends BakeStep


func get_id() -> StringName:
	return &"collect_brushes"


func get_display_name() -> String:
	return "CollectBrushesStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	var collector = BrushCollector.new()
	context.brushes = collector.collect(context.room)
	return context
