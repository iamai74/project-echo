## TopologyValidator unit tests.
## Covers: shape from neighbours, corner from neighbours, isolated cell, full cell, missing topology.
extends GdUnitTestSuite


func _make_topology(shape: CellShape.Value, corner: CellCorner.Value) -> SpatialTopology:
	var topo = SpatialTopology.new()
	topo.shape = shape
	topo.corner = corner
	return topo


func _make_topology_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value
) -> SemanticSpatialTopologyCell:
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = position
	cell.topology = _make_topology(shape, corner)
	return cell


func _make_context_with_platforms(cells: Array[SemanticSpatialCell]) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.semantic_data.spatial_layers.set_cells(SpatialLayer.SpatialType.PLATFORM, cells)
	return context


# --- Isolated cell: no neighbours -> SINGLE + ALL ---

func test_isolated_cell_correct_topology() -> void:
	var validator = TopologyValidator.new()
	var cell = _make_topology_cell(Vector2i(5, 5), CellShape.Value.SINGLE, CellCorner.Value.ALL)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_platforms(cells)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_isolated_cell_wrong_shape_fails() -> void:
	var validator = TopologyValidator.new()
	var cell = _make_topology_cell(Vector2i(5, 5), CellShape.Value.FULL, CellCorner.Value.NO)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_platforms(cells)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


# --- Full cell: all 4 neighbours present -> FULL + NO ---

func test_full_cell_correct_topology() -> void:
	var validator = TopologyValidator.new()
	var center = Vector2i(1, 1)
	var cells: Array[SemanticSpatialCell] = [
		_make_topology_cell(center, CellShape.Value.FULL, CellCorner.Value.NO),
		_make_topology_cell(center + Vector2i.UP, CellShape.Value.SINGLE, CellCorner.Value.TOP),
		_make_topology_cell(center + Vector2i.DOWN, CellShape.Value.SINGLE, CellCorner.Value.BOTTOM),
		_make_topology_cell(center + Vector2i.LEFT, CellShape.Value.SINGLE, CellCorner.Value.LEFT),
		_make_topology_cell(center + Vector2i.RIGHT, CellShape.Value.SINGLE, CellCorner.Value.RIGHT),
	]
	var context = _make_context_with_platforms(cells)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


# --- Missing topology data ---

func test_missing_topology_reports_error() -> void:
	var validator = TopologyValidator.new()
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = Vector2i(0, 0)
	# topology is null
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_platforms(cells)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()
	assert_bool(context.report.is_has_saverity(BakeIssue.Severity.ERROR)).is_true()
