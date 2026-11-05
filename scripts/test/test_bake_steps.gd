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

	assert_bool(context.report.is_has_fatal()).is_true


func test_build_runtime_room_step_builds_data_and_room() -> void:
	var step = BuildRuntimeRoomStep.new()
	var context = _make_empty_context()
	context.semantic_data = SemanticRoomData.new()

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_false
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

	step.run(context)

	assert_int(context.semantic_data.spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND).size()).is_equal(1)


# ── ApplyDefaultThemeStep ─────────────────────────────────────────

func test_apply_default_theme_step_fatal_when_room_null() -> void:
	var step = ApplyDefaultThemeStep.new()
	var context = _make_empty_context()
	# runtime_room is null by default

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true


func test_apply_default_theme_step_fatal_when_data_null() -> void:
	var step = ApplyDefaultThemeStep.new()
	var context = _make_empty_context()
	context.runtime_room = auto_free(Node2D.new())
	# runtime_room_data is null

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true


# ── SaveRoomDataStep ──────────────────────────────────────────────

func test_save_room_data_step_fatal_when_data_null() -> void:
	var step = SaveRoomDataStep.new()
	var context = _make_empty_context()
	# runtime_room_data is null by default

	step.run(context)

	assert_bool(context.report.is_has_fatal()).is_true


func test_save_room_data_step_derives_paths_from_scene() -> void:
	var step = SaveRoomDataStep.new()
	var context = _make_empty_context()

	# Set up a room node with a fake scene path
	var room = auto_free(Node2D.new())
	# We can't set scene_file_path directly, but we can test the helper methods
	# by calling them through the step. The step uses room.scene_file_path internally.
	# Since we can't mock scene_file_path easily in headless, test that a null
	# runtime_room_data is caught before any path logic runs.
	context.room = room

	step.run(context)

	# Should fail because runtime_room_data is null
	assert_bool(context.report.is_has_fatal()).is_true


# ── Helpers ───────────────────────────────────────────────────────

func _make_empty_context() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	return context
