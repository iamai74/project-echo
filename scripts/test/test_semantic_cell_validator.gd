## SemanticCellValidator unit tests.
## Covers: valid shapes, invalid combinations, valid/invalid traits, platform vs wall rules.
extends GdUnitTestSuite


func _make_topology(shape: CellShape.Value, corner: CellCorner.Value) -> SpatialTopology:
	var topo = SpatialTopology.new()
	topo.shape = shape
	topo.corner = corner
	return topo


func _make_platform_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value, traits: Array[SemanticSpatialPlatformCell.Trait]
) -> SemanticSpatialPlatformCell:
	var cell = SemanticSpatialPlatformCell.new()
	cell.cell = position
	cell.topology = _make_topology(shape, corner)
	cell.traits = traits
	return cell


func _make_wall_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value
) -> SemanticSpatialTopologyCell:
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = position
	cell.topology = _make_topology(shape, corner)
	return cell


func _make_context_with_cells(cells: Array[SemanticSpatialCell], type: SpatialLayer.SpatialType) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.semantic_data.spatial_layers.set_cells(type, cells)
	return context


# --- Shape validation ---

func test_valid_platform_shape_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_valid_platform_full_shape_no_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.FULL, CellCorner.Value.NO, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


# --- Combination validation ---

func test_full_shape_with_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.FULL, CellCorner.Value.ALL, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_single_shape_with_valid_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.TOP, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_single_shape_with_all_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.ALL, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


# --- Trait validation ---

func test_valid_traits_pass() -> void:
	var validator = SemanticCellValidator.new()
	var traits: Array[SemanticSpatialPlatformCell.Trait] = [SemanticSpatialPlatformCell.Trait.ONE_WAY]
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO, traits)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_empty_traits_pass() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_wall_cell_with_null_topology_skipped() -> void:
	var validator = SemanticCellValidator.new()
	var cell = SemanticSpatialTopologyCell.new()
	cell.cell = Vector2i(0, 0)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.WALL)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_cell_without_topology_skipped() -> void:
	var validator = SemanticCellValidator.new()
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(0, 0)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()
