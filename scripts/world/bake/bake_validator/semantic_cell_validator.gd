class_name SemanticCellValidator
extends BakeValidator

const _FLOOR_SHAPES: Array[CellShape.Value] = [
	CellShape.Value.SINGLE,
	CellShape.Value.TOP,
	CellShape.Value.BOTTOM,
	CellShape.Value.LEFT,
	CellShape.Value.RIGHT,
	CellShape.Value.FULL,
]

const _WALL_SHAPES: Array[CellShape.Value] = [
	CellShape.Value.SINGLE,
	CellShape.Value.TOP,
	CellShape.Value.BOTTOM,
	CellShape.Value.LEFT,
	CellShape.Value.RIGHT,
	CellShape.Value.FULL,
]

const _FLOOR_CORNERS: Array[CellCorner.Value] = [
	CellCorner.Value.NO,
	CellCorner.Value.ALL,
	CellCorner.Value.TOP,
	CellCorner.Value.BOTTOM,
	CellCorner.Value.LEFT,
	CellCorner.Value.RIGHT,
	CellCorner.Value.TOP_LEFT,
	CellCorner.Value.TOP_RIGHT,
	CellCorner.Value.BOTTOM_LEFT,
	CellCorner.Value.BOTTOM_RIGHT,
]

const _WALL_CORNERS: Array[CellCorner.Value] = [
	CellCorner.Value.NO,
	CellCorner.Value.ALL,
	CellCorner.Value.TOP,
	CellCorner.Value.BOTTOM,
	CellCorner.Value.LEFT,
	CellCorner.Value.RIGHT,
	CellCorner.Value.TOP_LEFT,
	CellCorner.Value.TOP_RIGHT,
	CellCorner.Value.BOTTOM_LEFT,
	CellCorner.Value.BOTTOM_RIGHT,
]

const _VALIDATE_TYPES: Array[SpatialLayer.SpatialType] = [
	SpatialLayer.SpatialType.FLOOR,
	SpatialLayer.SpatialType.WALL,
]


func validate(context: RoomBakeContext) -> void:
	for type in _VALIDATE_TYPES:
		_validate_type(type, context)


func _validate_type(type: SpatialLayer.SpatialType, context: RoomBakeContext) -> void:
	var layout: Array[SemanticSpatialCell] = context.semantic_data.spatial_layers.get_cells(type)
	for cell in layout:
		var topology_cell := cell as SemanticSpatialTopologyCell
		if topology_cell == null || topology_cell.topology == null:
			continue

		var topo: SpatialTopology = topology_cell.topology
		var topo_shape := topo.shape
		var topo_corner := topo.corner

		if !(_is_acceptable_shape(topo_shape, type)):
			context.report.add_error(
				_create_issue(
					type, cell, "cell has unacceptable shape " + CellShape.Value.keys()[topo_shape]
				)
			)
		if !(_is_acceptable_corner(topo_corner, type)):
			context.report.add_error(
				_create_issue(
					type,
					cell,
					"cell has unacceptable corner " + CellCorner.Value.keys()[topo_corner]
				)
			)
		if !(_is_acceptable_combination(topo_shape, topo_corner)):
			context.report.add_error(
				_create_issue(
					type,
					cell,
					(
						"shape "
						+ CellShape.Value.keys()[topo_shape]
						+ " + corner "
						+ CellCorner.Value.keys()[topo_corner]
						+ " is not a valid combination"
					)
				)
			)
		if !(_are_valid_traits(cell)):
			context.report.add_error(_create_issue(type, cell, "cell has invalid traits"))


func _is_acceptable_shape(shape: CellShape.Value, type: SpatialLayer.SpatialType) -> bool:
	return (
		type == SpatialLayer.SpatialType.FLOOR && shape in _FLOOR_SHAPES
		|| type == SpatialLayer.SpatialType.WALL && shape in _WALL_SHAPES
	)


func _is_acceptable_corner(corner: CellCorner.Value, type: SpatialLayer.SpatialType) -> bool:
	return (
		type == SpatialLayer.SpatialType.FLOOR && corner in _FLOOR_CORNERS
		|| type == SpatialLayer.SpatialType.WALL && corner in _WALL_CORNERS
	)


func _is_acceptable_combination(shape: CellShape.Value, corner: CellCorner.Value) -> bool:
	var result: bool = true

	if shape == CellShape.Value.FULL:
		result = corner == CellCorner.Value.NO
	elif shape == CellShape.Value.SINGLE:
		result = (
			corner
			in [
				CellCorner.Value.NO,
				CellCorner.Value.ALL,
				CellCorner.Value.TOP,
				CellCorner.Value.BOTTOM,
				CellCorner.Value.LEFT,
				CellCorner.Value.RIGHT,
			]
		)
	else:
		if corner == CellCorner.Value.NO:
			result = true
		elif corner == CellCorner.Value.ALL:
			result = false
		elif corner == CellCorner.Value.TOP:
			result = shape in [CellShape.Value.BOTTOM, CellShape.Value.TOP]
		elif corner == CellCorner.Value.BOTTOM:
			result = shape in [CellShape.Value.TOP, CellShape.Value.BOTTOM]
		elif corner == CellCorner.Value.LEFT:
			result = shape in [CellShape.Value.RIGHT, CellShape.Value.LEFT]
		elif corner == CellCorner.Value.RIGHT:
			result = shape in [CellShape.Value.LEFT, CellShape.Value.RIGHT]
		elif corner == CellCorner.Value.TOP_LEFT:
			result = shape in [CellShape.Value.TOP, CellShape.Value.LEFT]
		elif corner == CellCorner.Value.TOP_RIGHT:
			result = shape in [CellShape.Value.TOP, CellShape.Value.RIGHT]
		elif corner == CellCorner.Value.BOTTOM_LEFT:
			result = shape in [CellShape.Value.BOTTOM, CellShape.Value.LEFT]
		elif corner == CellCorner.Value.BOTTOM_RIGHT:
			result = shape in [CellShape.Value.BOTTOM, CellShape.Value.RIGHT]
		else:
			result = false

	return result


func _are_valid_traits(cell: SemanticSpatialCell) -> bool:
	var floor_cell := cell as SemanticSpatialFloorCell
	if floor_cell == null:
		return true

	for item in floor_cell.traits:
		if item < 0 || item >= SemanticSpatialFloorCell.Trait.keys().size():
			return false

	return true


func _create_issue(
	type: SpatialLayer.SpatialType, cell: SemanticSpatialCell, message: String
) -> BakeIssue:
	return BakeIssue.new(
		BakeIssue.IssueType.SEMANTIC_CONFLICT,
		BakeIssue.Severity.ERROR,
		SpatialLayer.SpatialType.keys()[type] + " " + message,
		cell.cell
	)
