class_name SemanticCellValidator
extends BakeValidator

const _FLOOR_SHAPES: Array[SpatialTopology.Shape] = [
	SpatialTopology.Shape.SINGLE,
	SpatialTopology.Shape.TOP,
	SpatialTopology.Shape.BOTTOM,
	SpatialTopology.Shape.LEFT,
	SpatialTopology.Shape.RIGHT,
	SpatialTopology.Shape.FULL,
]

const _WALL_SHAPES: Array[SpatialTopology.Shape] = [
	SpatialTopology.Shape.SINGLE,
	SpatialTopology.Shape.TOP,
	SpatialTopology.Shape.BOTTOM,
	SpatialTopology.Shape.LEFT,
	SpatialTopology.Shape.RIGHT,
	SpatialTopology.Shape.FULL,
]

const _FLOOR_CORNERS: Array[SpatialTopology.Corner] = [
	SpatialTopology.Corner.NO,
	SpatialTopology.Corner.ALL,
	SpatialTopology.Corner.TOP,
	SpatialTopology.Corner.BOTTOM,
	SpatialTopology.Corner.LEFT,
	SpatialTopology.Corner.RIGHT,
	SpatialTopology.Corner.TOP_LEFT,
	SpatialTopology.Corner.TOP_RIGHT,
	SpatialTopology.Corner.BOTTOM_LEFT,
	SpatialTopology.Corner.BOTTOM_RIGHT,
]

const _WALL_CORNERS: Array[SpatialTopology.Corner] = [
	SpatialTopology.Corner.NO,
	SpatialTopology.Corner.ALL,
	SpatialTopology.Corner.TOP,
	SpatialTopology.Corner.BOTTOM,
	SpatialTopology.Corner.LEFT,
	SpatialTopology.Corner.RIGHT,
	SpatialTopology.Corner.TOP_LEFT,
	SpatialTopology.Corner.TOP_RIGHT,
	SpatialTopology.Corner.BOTTOM_LEFT,
	SpatialTopology.Corner.BOTTOM_RIGHT,
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
					type,
					cell,
					"cell has unacceptable shape " + SpatialTopology.Shape.keys()[topo_shape]
				)
			)
		if !(_is_acceptable_corner(topo_corner, type)):
			context.report.add_error(
				_create_issue(
					type,
					cell,
					"cell has unacceptable corner " + SpatialTopology.Corner.keys()[topo_corner]
				)
			)
		if !(_is_acceptable_combination(topo_shape, topo_corner)):
			context.report.add_error(
				_create_issue(
					type,
					cell,
					(
						"shape "
						+ SpatialTopology.Shape.keys()[topo_shape]
						+ " + corner "
						+ SpatialTopology.Corner.keys()[topo_corner]
						+ " is not a valid combination"
					)
				)
			)
		if !(_are_valid_traits(cell)):
			context.report.add_error(_create_issue(type, cell, "cell has invalid traits"))


func _is_acceptable_shape(shape: SpatialTopology.Shape, type: SpatialLayer.SpatialType) -> bool:
	return (
		type == SpatialLayer.SpatialType.FLOOR && shape in _FLOOR_SHAPES
		|| type == SpatialLayer.SpatialType.WALL && shape in _WALL_SHAPES
	)


func _is_acceptable_corner(corner: SpatialTopology.Corner, type: SpatialLayer.SpatialType) -> bool:
	return (
		type == SpatialLayer.SpatialType.FLOOR && corner in _FLOOR_CORNERS
		|| type == SpatialLayer.SpatialType.WALL && corner in _WALL_CORNERS
	)


func _is_acceptable_combination(
	shape: SpatialTopology.Shape, corner: SpatialTopology.Corner
) -> bool:
	var result: bool = true

	if shape == SpatialTopology.Shape.FULL:
		result = corner == SpatialTopology.Corner.NO
	elif shape == SpatialTopology.Shape.SINGLE:
		result = (
			corner
			in [
				SpatialTopology.Corner.NO,
				SpatialTopology.Corner.ALL,
				SpatialTopology.Corner.TOP,
				SpatialTopology.Corner.BOTTOM,
				SpatialTopology.Corner.LEFT,
				SpatialTopology.Corner.RIGHT,
			]
		)
	else:
		if corner == SpatialTopology.Corner.NO:
			result = true
		elif corner == SpatialTopology.Corner.ALL:
			result = false
		elif corner == SpatialTopology.Corner.TOP:
			result = shape in [SpatialTopology.Shape.BOTTOM, SpatialTopology.Shape.TOP]
		elif corner == SpatialTopology.Corner.BOTTOM:
			result = shape in [SpatialTopology.Shape.TOP, SpatialTopology.Shape.BOTTOM]
		elif corner == SpatialTopology.Corner.LEFT:
			result = shape in [SpatialTopology.Shape.RIGHT, SpatialTopology.Shape.LEFT]
		elif corner == SpatialTopology.Corner.RIGHT:
			result = shape in [SpatialTopology.Shape.LEFT, SpatialTopology.Shape.RIGHT]
		elif corner == SpatialTopology.Corner.TOP_LEFT:
			result = shape in [SpatialTopology.Shape.TOP, SpatialTopology.Shape.LEFT]
		elif corner == SpatialTopology.Corner.TOP_RIGHT:
			result = shape in [SpatialTopology.Shape.TOP, SpatialTopology.Shape.RIGHT]
		elif corner == SpatialTopology.Corner.BOTTOM_LEFT:
			result = shape in [SpatialTopology.Shape.BOTTOM, SpatialTopology.Shape.LEFT]
		elif corner == SpatialTopology.Corner.BOTTOM_RIGHT:
			result = shape in [SpatialTopology.Shape.BOTTOM, SpatialTopology.Shape.RIGHT]
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
