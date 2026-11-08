## SemanticCellValidator extended failure-path tests.
## Covers: edge shape + corner combinations, invalid traits, wall type errors,
## multiple issues on one cell.
extends GdUnitTestSuite


func _make_topology(shape: CellShape.Value, corner: CellCorner.Value) -> SpatialTopology:
	var topo = SpatialTopology.new()
	topo.shape = shape
	topo.corner = corner
	return topo


func _make_platform_cell(
	position: Vector2i, shape: CellShape.Value, corner: CellCorner.Value,
	traits: Array[SemanticSpatialPlatformCell.Trait]
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


func _make_context_with_cells(
	cells: Array[SemanticSpatialCell], type: SpatialLayer.SpatialType
) -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.semantic_data = SemanticRoomData.new()
	context.report = BakeReport.new()
	context.semantic_data.spatial_layers.set_cells(type, cells)
	return context


# ── Edge shape + corner combinations ─────────────────────────────
# TOP shape:
#   NO -> true
#   ALL -> false
#   TOP -> true
#   BOTTOM -> true
#   LEFT -> false
#   RIGHT -> false
#   TOP_LEFT -> true
#   TOP_RIGHT -> true
#   BOTTOM_LEFT -> false
#   BOTTOM_RIGHT -> false

func test_top_shape_no_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.NO, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_top_shape_all_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.ALL, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_top_shape_bottom_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.BOTTOM, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_top_shape_left_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.LEFT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_top_shape_top_left_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.TOP_LEFT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_top_shape_bottom_right_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.BOTTOM_RIGHT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


# ── BOTTOM shape combinations ────────────────────────────────────

func test_bottom_shape_right_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.BOTTOM, CellCorner.Value.RIGHT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_bottom_shape_bottom_left_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.BOTTOM, CellCorner.Value.BOTTOM_LEFT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


# ── LEFT / RIGHT shape combinations ──────────────────────────────

func test_left_shape_left_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.LEFT, CellCorner.Value.LEFT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_left_shape_bottom_corner_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.LEFT, CellCorner.Value.BOTTOM, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


func test_right_shape_top_right_corner_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(Vector2i(0, 0), CellShape.Value.RIGHT, CellCorner.Value.TOP_RIGHT, [])
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


# ── Invalid traits ───────────────────────────────────────────────

func test_invalid_trait_value_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_platform_cell(
		Vector2i(0, 0), CellShape.Value.SINGLE, CellCorner.Value.NO,
		[SemanticSpatialPlatformCell.Trait.keys().size()]  # out of range
	)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


# ── Wall type validation ─────────────────────────────────────────

func test_wall_cell_valid_combination_passes() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_wall_cell(Vector2i(0, 0), CellShape.Value.TOP, CellCorner.Value.NO)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.WALL)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_false()


func test_wall_cell_invalid_combination_fails() -> void:
	var validator = SemanticCellValidator.new()
	var cell = _make_wall_cell(Vector2i(0, 0), CellShape.Value.FULL, CellCorner.Value.ALL)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.WALL)
	validator.validate(context)
	assert_bool(context.report.is_has_issues()).is_true()


# ── Multiple issues on a single cell ─────────────────────────────

func test_cell_with_multiple_issues_reports_all() -> void:
	var validator = SemanticCellValidator.new()
	# FULL + ALL is invalid shape+corner combination
	# Also gives us multiple error checks on same cell
	var cell = _make_platform_cell(
		Vector2i(0, 0), CellShape.Value.FULL, CellCorner.Value.ALL,
		[]
	)
	var cells: Array[SemanticSpatialCell] = [cell]
	var context = _make_context_with_cells(cells, SpatialLayer.SpatialType.PLATFORM)
	validator.validate(context)
	var all = context.report.get_all_issues()
	# Should have SEMANTIC_CONFLICT issues
	assert_bool(all.has(BakeIssue.IssueType.SEMANTIC_CONFLICT)).is_true()
	# Combination issue is the main failure here
	assert_int(all[BakeIssue.IssueType.SEMANTIC_CONFLICT].size()).is_greater(0)
