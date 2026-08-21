class_name PostProcessStep
extends BakeStep


func get_id() -> StringName:
	return &"post_process"


func get_display_name() -> String:
	return "PostProcessStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	var bake_topology_processor = PostBakeTopologyProcessor.new()
	var update_layers: Array[SpatialLayer.SpatialType] = [
		SpatialLayer.SpatialType.FLOOR, SpatialLayer.SpatialType.WALL
	]
	for type in update_layers:
		var old_data = context.semantic_data.spatial_layers.get_cells(type)
		var new_data = bake_topology_processor.execute(old_data)
		context.semantic_data.spatial_layers.set_cells(type, new_data)
	return context
