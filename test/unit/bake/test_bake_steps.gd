## Test suite for bake step classes.
## Covers: CollectBrushesStep, InitSemanticDataStep, BuildRuntimeRoomStep,
## PostProcessStep, ApplyDefaultThemeStep, and SaveRoomDataStep.
extends GdUnitTestSuite


# ── CollectBrushesStep ─────────────────────────────────────────────

func test_collect_brushes_step_delegates_to_collector() -> void:
	var collector = BrushCollector.new()
	var step = CollectBrushesStep.new(collector)
	var context = _make_empty_context()

	# Create a minimal room node with a platform brush child
	var room = auto_free(Node2D.new())
	var brush = PlatformBrush.new()
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)
	room.add_child(brush)
	context.room = room

	step.run(context)

	assert_object(context.brushes).is_not_null()
	assert_int(context.brushes.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)


func test_collect_brushes_step_empty_room() -> void:
	var collector = BrushCollector.new()
	var step = CollectBrushesStep.new(collector)
	var context = _make_empty_context()
	var room = auto_free(Node2D.new())
	context.room = room

	step.run(context)

	assert_object(context.brushes).is_not_null()


func test_collect_brushes_step_copies_room_bounds_from_room_authoring() -> void:
	var collector = BrushCollector.new()
	var step = CollectBrushesStep.new(collector)
	var context = _make_empty_context()

	var room = auto_free(RoomAuthoring.new())
	room.room_bounds = RoomBounds.from_origin_and_size(Vector2i(-2, -3), Vector2i(8, 6))
	context.room = room

	step.run(context)

	assert_int(context.room_bounds.position.x).is_equal(-2)
	assert_int(context.room_bounds.position.y).is_equal(-3)
	assert_int(context.room_bounds.size.x).is_equal(8)
	assert_int(context.room_bounds.size.y).is_equal(6)


func test_collect_brushes_step_leaves_bounds_empty_for_plain_node() -> void:
	var collector = BrushCollector.new()
	var step = CollectBrushesStep.new(collector)
	var context = _make_empty_context()

	var room = auto_free(Node2D.new())
	room.add_child(auto_free(PlatformBrush.new()))
	context.room = room

	step.run(context)

	assert_bool(context.room_bounds == Rect2i()).is_true()


# ── InitSemanticDataStep ──────────────────────────────────────────

func test_init_semantic_data_creates_empty_data() -> void:
	var step = InitSemanticDataStep.new()
	var context = RoomBakeContext.new()

	step.run(context)

	assert_object(context.semantic_data).is_not_null()
	assert_object(context.semantic_data).is_class(&"SemanticRoomData")


# ── BuildRuntimeRoomStep ──────────────────────────────────────────

func test_build_runtime_room_step_fatal_when_semantic_data_null() -> void:
	var step = BuildRuntimeRoomStep.new()
	var context = _make_empty_context()
	# semantic_data is null by default

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()


func test_build_runtime_room_step_builds_data_and_room() -> void:
	var step = BuildRuntimeRoomStep.new()
	var context = _make_empty_context()
	context.semantic_data = SemanticRoomData.new()

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_object(context.runtime_room_data).is_not_null()
	assert_object(context.runtime_room).is_not_null()
	auto_free(context.runtime_room)


# ── PostProcessStep ───────────────────────────────────────────────

func test_post_process_step_updates_platform_topology() -> void:
	var step = PostProcessStep.new()
	var context = _make_empty_context()
	context.semantic_data = SemanticRoomData.new()

	# Add a platform cell
	var cell = SemanticSpatialPlatformCell.new()
	cell.cell = Vector2i(1, 1)
	var cells: Array[SemanticSpatialCell] = [cell]
	context.semantic_data.spatial_layers.add_cells(SpatialLayer.SpatialType.PLATFORM, cells)

	step.run(context)

	# After post-processing, platform cells should still exist (topology updated)
	assert_int(context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM).size()).is_equal(1)

	# PostProcessStep must actually update the platform cell's topology data.
	var platform_layer = context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_object(platform_layer[0]).is_class(&"SemanticSpatialPlatformCell")
	var platform_cell: SemanticSpatialPlatformCell = platform_layer[0] as SemanticSpatialPlatformCell
	assert_object(platform_cell.topology).is_not_null()
	# An isolated cell has no neighbors, so it bakes to a single cell with an all-corner shape.
	assert_int(platform_cell.topology.shape).is_equal(CellShape.Value.SINGLE)
	assert_int(platform_cell.topology.corner).is_equal(CellCorner.Value.ALL)


func test_post_process_step_leaves_background_untouched() -> void:
	var step = PostProcessStep.new()
	var context = _make_empty_context()
	context.semantic_data = SemanticRoomData.new()

	# Add a background cell
	var cell = SemanticSpatialCell.new()
	cell.cell = Vector2i(0, 0)
	var cells: Array[SemanticSpatialCell] = [cell]
	context.semantic_data.spatial_layers.add_cells(SpatialLayer.SpatialType.BACKGROUND, cells)

	# Add a platform cell too so post-processing runs
	var platform_cell = SemanticSpatialPlatformCell.new()
	platform_cell.cell = Vector2i(1, 1)
	var platform_cells: Array[SemanticSpatialCell] = [platform_cell]
	context.semantic_data.spatial_layers.add_cells(SpatialLayer.SpatialType.PLATFORM, platform_cells)

	# Capture the background cell's data before post-processing so we can prove
	# PostProcessStep leaves the BACKGROUND layer exactly as it was.
	var background_before = context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	var original_cell: SemanticSpatialCell = background_before[0]
	var original_position: Vector2i = original_cell.cell

	step.run(context)

	# The background layer must keep exactly one cell, and it must be the very
	# same cell at the same position. A plain SemanticSpatialCell has no
	# topology, so identity plus position together prove the cell is untouched.
	var background_after = context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND)
	assert_int(background_after.size()).is_equal(1)
	assert_bool(background_after[0] == original_cell).is_true()
	assert_int(background_after[0].cell.x).is_equal(original_position.x)
	assert_int(background_after[0].cell.y).is_equal(original_position.y)
	assert_object(background_after[0]).is_class(&"SemanticSpatialCell")


# ── ApplyDefaultThemeStep ─────────────────────────────────────────

func test_apply_default_theme_step_fatal_when_room_null() -> void:
	var step = ApplyDefaultThemeStep.new()
	var context = _make_empty_context()
	# runtime_room is null by default

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()


func test_apply_default_theme_step_fatal_when_data_null() -> void:
	var step = ApplyDefaultThemeStep.new()
	var context = _make_empty_context()
	context.runtime_room = auto_free(Node2D.new())
	# runtime_room_data is null

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true()


# ── Helpers ───────────────────────────────────────────────────────

func _make_empty_context() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	return context
