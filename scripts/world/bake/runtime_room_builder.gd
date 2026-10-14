class_name RuntimeRoomBuilder
extends RefCounted


func build(room_data: RoomData) -> Node2D:
	var runtime_room = Node2D.new()
	runtime_room.name = "RuntimeRoom"
	runtime_room = _add_semantic_layer(runtime_room)
	return runtime_room


func _add_semantic_layer(runtime_room: Node2D) -> Node2D:
	var layer_node = Node2D.new()
	layer_node.name = "Semantic"
	runtime_room.add_child(layer_node)

	var tilemap_layer = TileMapLayer.new()
	tilemap_layer.name = "Tiles"
	layer_node.add_child(tilemap_layer)
	return runtime_room
