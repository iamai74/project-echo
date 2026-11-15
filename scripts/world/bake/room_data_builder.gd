class_name RoomDataBuilder
extends RefCounted


func build(semantic_data: SemanticRoomData, room_bounds: Rect2i) -> RoomData:
	var room_data := RoomData.new()

	room_data.version = 2
	room_data.room_bounds = room_bounds
	room_data.geometry_bounds = GeometryBounds.compute(semantic_data.spatial_layers)
	room_data.platforms = _to_semantic_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	)
	room_data.walls = _to_semantic_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)
	)
	room_data.background = _to_background_cells(
		semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	)
	room_data.markers = _sorted_markers(semantic_data.markers.get_all_markers())
	room_data.connections = _sorted_connections(semantic_data.connections)

	return room_data


func _to_semantic_cells(source: Array[SemanticSpatialCell]) -> Array[SemanticCell]:
	var result: Array[SemanticCell] = []
	for cell in source:
		var sc = SemanticCell.new()
		sc.position = cell.cell
		sc.shape = _read_shape(cell)
		sc.corners = _read_corner(cell)
		result.append(sc)
	return result


func _to_background_cells(source: Array[SemanticSpatialCell]) -> Array[BackgroundCell]:
	var result: Array[BackgroundCell] = []
	for cell in source:
		var bc = BackgroundCell.new()
		bc.position = cell.cell
		result.append(bc)
	return result


func _sorted_markers(source: Array[MarkerData]) -> Array[MarkerData]:
	var markers: Array[MarkerData] = []
	for marker in source:
		markers.append(marker.duplicate_deep() as MarkerData)
	markers.sort_custom(_marker_before)
	return markers


func _sorted_connections(source: Array[ConnectionData]) -> Array[ConnectionData]:
	var connections: Array[ConnectionData] = []
	for connection in source:
		connections.append(connection.duplicate_deep() as ConnectionData)
	connections.sort_custom(_connection_before)
	return connections


func _marker_before(a: MarkerData, b: MarkerData) -> bool:
	if a.type != b.type:
		return a.type < b.type
	if a.position.y != b.position.y:
		return a.position.y < b.position.y
	if a.position.x != b.position.x:
		return a.position.x < b.position.x
	var marker_id_a := String(a.marker_id)
	var marker_id_b := String(b.marker_id)
	if marker_id_a != marker_id_b:
		return marker_id_a < marker_id_b
	return String(a.content_id) < String(b.content_id)


func _connection_before(a: ConnectionData, b: ConnectionData) -> bool:
	if a.side != b.side:
		return a.side < b.side
	if a.position.y != b.position.y:
		return a.position.y < b.position.y
	if a.position.x != b.position.x:
		return a.position.x < b.position.x
	if a.size.x != b.size.x:
		return a.size.x < b.size.x
	if a.size.y != b.size.y:
		return a.size.y < b.size.y
	return String(a.id) < String(b.id)


func _read_shape(cell: SemanticSpatialCell) -> CellShape.Value:
	var topo = cell as SemanticSpatialTopologyCell
	if topo != null and topo.topology != null:
		return topo.topology.shape
	return CellShape.Value.SINGLE


func _read_corner(cell: SemanticSpatialCell) -> CellCorner.Value:
	var topo = cell as SemanticSpatialTopologyCell
	if topo != null and topo.topology != null:
		return topo.topology.corner
	return CellCorner.Value.NO
