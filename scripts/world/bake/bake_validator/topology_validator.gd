class_name TopologyValidator
extends BakeValidator

const _VALIDATE_TYPES: Array[SpatialLayer.SpatialType] = [
	SpatialLayer.SpatialType.FLOOR, SpatialLayer.SpatialType.WALL
]


func validate(context: RoomBakeContext) -> void:
	for type in _VALIDATE_TYPES:
		_validate_type(type, context)


func _validate_type(type: SpatialLayer.SpatialType, context: RoomBakeContext) -> void:
	var layout: Array[SemanticSpatialCell] = context.semantic_data.spatial_layers.get_cells(type)
	var occupied := _collect_occupied(layout)
	for cell in layout:
		var topology_cell := cell as SemanticSpatialTopologyCell
		if topology_cell == null || topology_cell.topology == null:
			context.report.add_error(_create_issue(type, cell, "Cell has no topology data"))
			continue
		var neighbors := _collect_neighbors(cell.cell, occupied)
		if !_validate_cell_shape(topology_cell, neighbors):
			context.report.add_error(
				_create_issue(type, cell, _describe_shape_mismatch(topology_cell, neighbors))
			)
		if !_validate_cell_corner(topology_cell, neighbors):
			context.report.add_error(
				_create_issue(type, cell, _describe_corner_mismatch(topology_cell, neighbors))
			)


func _validate_cell_shape(cell: SemanticSpatialTopologyCell, neighbors: Dictionary) -> bool:
	return cell.topology.shape == _expected_shape(neighbors)


func _expected_shape(neighbors: Dictionary) -> SpatialTopology.Shape:
	var no_vertical: bool = !neighbors[Vector2i.UP] && !neighbors[Vector2i.DOWN]
	var no_horizontal: bool = !neighbors[Vector2i.LEFT] && !neighbors[Vector2i.RIGHT]
	if no_vertical || no_horizontal:
		return SpatialTopology.Shape.SINGLE
	if !neighbors[Vector2i.UP]:
		return SpatialTopology.Shape.TOP
	if !neighbors[Vector2i.DOWN]:
		return SpatialTopology.Shape.BOTTOM
	if !neighbors[Vector2i.LEFT]:
		return SpatialTopology.Shape.LEFT
	if !neighbors[Vector2i.RIGHT]:
		return SpatialTopology.Shape.RIGHT
	return SpatialTopology.Shape.FULL


func _collect_occupied(layout: Array[SemanticSpatialCell]) -> Dictionary:
	var occupied := {}
	for cell in layout:
		occupied[cell.cell] = true
	return occupied


func _collect_neighbors(cell: Vector2i, occupied: Dictionary) -> Dictionary:
	return {
		Vector2i.UP: occupied.has(cell + Vector2i.UP),
		Vector2i.DOWN: occupied.has(cell + Vector2i.DOWN),
		Vector2i.LEFT: occupied.has(cell + Vector2i.LEFT),
		Vector2i.RIGHT: occupied.has(cell + Vector2i.RIGHT),
	}


func _validate_cell_corner(cell: SemanticSpatialTopologyCell, neighbors: Dictionary) -> bool:
	return cell.topology.corner == _expected_corner(neighbors)


func _expected_corner(neighbors: Dictionary) -> SpatialTopology.Corner:
	var shape = _expected_shape(neighbors)
	if shape == SpatialTopology.Shape.FULL:
		return SpatialTopology.Corner.NO
	if shape == SpatialTopology.Shape.SINGLE:
		return _expected_single_corner(neighbors)
	return _expected_edge_corner(neighbors)


func _expected_single_corner(neighbors: Dictionary) -> SpatialTopology.Corner:
	var top = neighbors[Vector2i.UP]
	var bottom = neighbors[Vector2i.DOWN]
	var left = neighbors[Vector2i.LEFT]
	var right = neighbors[Vector2i.RIGHT]
	var corner := SpatialTopology.Corner.NO

	if !top and !bottom:
		if !left and !right:
			corner = SpatialTopology.Corner.ALL
		elif !left:
			corner = SpatialTopology.Corner.LEFT
		elif !right:
			corner = SpatialTopology.Corner.RIGHT
	elif !left and !right:
		if !top:
			corner = SpatialTopology.Corner.TOP
		elif !bottom:
			corner = SpatialTopology.Corner.BOTTOM

	return corner


func _expected_edge_corner(neighbors: Dictionary) -> SpatialTopology.Corner:
	var top = neighbors[Vector2i.UP]
	var bottom = neighbors[Vector2i.DOWN]
	var left = neighbors[Vector2i.LEFT]
	var right = neighbors[Vector2i.RIGHT]

	if !top and !left:
		return SpatialTopology.Corner.TOP_LEFT
	if !top and !right:
		return SpatialTopology.Corner.TOP_RIGHT
	if !bottom and !left:
		return SpatialTopology.Corner.BOTTOM_LEFT
	if !bottom and !right:
		return SpatialTopology.Corner.BOTTOM_RIGHT
	return SpatialTopology.Corner.NO


func _describe_corner_mismatch(cell: SemanticSpatialTopologyCell, neighbors: Dictionary) -> String:
	return (
		"cell topology corner "
		+ SpatialTopology.Corner.keys()[cell.topology.corner]
		+ " does not match neighbors, expected "
		+ SpatialTopology.Corner.keys()[_expected_corner(neighbors)]
	)


func _describe_shape_mismatch(cell: SemanticSpatialTopologyCell, neighbors: Dictionary) -> String:
	return (
		"cell topology shape "
		+ SpatialTopology.Shape.keys()[cell.topology.shape]
		+ " does not match neighbors, expected "
		+ SpatialTopology.Shape.keys()[_expected_shape(neighbors)]
	)


func _create_issue(
	type: SpatialLayer.SpatialType, cell: SemanticSpatialCell, message: String
) -> BakeIssue:
	return BakeIssue.new(
		BakeIssue.IssueType.SEMANTIC_CONFLICT,
		BakeIssue.Severity.ERROR,
		SpatialLayer.SpatialType.keys()[type] + " " + message,
		cell.cell
	)
