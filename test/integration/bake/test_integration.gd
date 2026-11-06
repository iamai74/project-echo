## Integration tests.
## Covers: Player scene boot and state transitions, enemy detection-chase-attack-patrol
## cycle, full bake pipeline end-to-end, and runtime room structure.
extends GdUnitTestSuite


const Fixture = preload("res://test/fixtures/actor_state_fixture.gd")


# ── Player scene boot and transitions ───────────────────────────────

func test_player_boots_into_idle() -> void:
	var player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)

	assert_str(player.state_machine.current_state.name).is_equal("Idle")


func test_player_moves_when_input_present() -> void:
	var player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)

	var idle = player.state_machine.states["Idle"] as PlayerState
	player.grounded = true
	player.input_component.get_command().move_direction = 1.0

	idle.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Move")


func test_player_jumps_when_grounded_and_jump_command() -> void:
	var player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)

	var idle = player.state_machine.states["Idle"] as PlayerState
	player.grounded = true
	player.jump_count = 1
	player.input_component.get_command().add_command(Command.new(CommandType.Type.JUMP))

	idle.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Jump")


func test_player_attacks_when_attack_command() -> void:
	var player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)

	var idle = player.state_machine.states["Idle"] as PlayerState
	player.grounded = true
	player.input_component.get_command().add_command(Command.new(CommandType.Type.ATTACK))

	idle.physics_update(0.0)

	assert_str(player.state_machine.current_state.name).is_equal("Attack")


func test_player_dies_when_health_depleted() -> void:
	var player = auto_free(Fixture.build_player())
	Fixture.add_player_states(player)
	Fixture.start(player)

	# Deplete health directly
	player.health.current_health = 0
	player.health.emit_signal("died")

	assert_str(player.state_machine.current_state.name).is_equal("Dead")
	assert_bool(player.died).is_true()


# ── Enemy detection → chase → attack → patrol cycle ─────────────────

func test_enemy_detects_player_and_chases() -> void:
	var enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy, "Patrol")

	enemy.grounded = true
	enemy.target_position = Vector2(200.0, 0.0)  # Player detected at distance

	var chase = enemy.state_machine.states["Chase"] as EnemyState
	enemy.state_machine.change_state("Chase")
	chase.physics_update(0.0)

	assert_float(enemy.velocity.x).is_equal(enemy.data.move_speed)


func test_enemy_attacks_when_in_range() -> void:
	var enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy, "Patrol")

	enemy.grounded = true
	enemy.target_position = Vector2(10.0, 0.0)  # Player very close

	var chase = enemy.state_machine.states["Chase"] as EnemyState
	enemy.state_machine.change_state("Chase")
	chase.physics_update(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Attack")


func test_enemy_returns_to_patrol_when_target_lost() -> void:
	var enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy, "Patrol")

	enemy.grounded = true
	enemy.target_position = Vector2.INF  # Player out of detection range

	var chase = enemy.state_machine.states["Chase"] as EnemyState
	enemy.state_machine.change_state("Chase")
	chase.physics_update(0.0)

	assert_str(enemy.state_machine.current_state.name).is_equal("Patrol")


func test_enemy_attack_finishes_into_idle_when_grounded() -> void:
	var enemy = auto_free(Fixture.build_enemy())
	Fixture.add_enemy_states(enemy)
	Fixture.start_enemy(enemy)

	enemy.grounded = true
	enemy.state_machine.change_state("Attack")
	enemy.state_machine.handle_attack_finished(AttackDefinition.new())

	assert_str(enemy.state_machine.current_state.name).is_equal("Idle")


# ── Full bake pipeline end-to-end ───────────────────────────────────

# Helper: build a pipeline with all default steps except SaveRoomDataStep,
# which requires context.room.scene_file_path to be set (unavailable for
# plain Node2D test fixtures).
func _make_pipeline_without_save() -> BakePipeline:
	var registry = _create_test_registry()
	var collector = BrushCollector.new()
	var steps: Array[BakeStep] = [
		CollectBrushesStep.new(collector),
		InitSemanticDataStep.new(),
		BakeSemanticLayerStep.new(registry),
		PostProcessStep.new(),
		ValidateStep.new(),
		BuildRuntimeRoomStep.new(),
		ApplyDefaultThemeStep.new(),
	]
	return BakePipeline.new(steps)


func _create_test_registry() -> BakeProcessorRegistry:
	var registry = BakeProcessorRegistry.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, PlatformBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.WALL, WallBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.BACKGROUND, BackgroundBakeProcessor.new())
	return registry


func test_bake_pipeline_runs_from_brushes_to_themed_room() -> void:
	var pipeline = _make_pipeline_without_save()
	var context = _make_bake_context_with_platform()

	var result = pipeline.run(context)

	# Pipeline should complete without fatal errors
	assert_bool(result.report.is_has_fatal()).is_false()
	# Runtime room data should be populated
	assert_object(result.runtime_room_data).is_not_null()
	# Runtime room should have Semantic and Tiles children
	assert_object(result.runtime_room).is_not_null()
	var semantic = result.runtime_room.get_node_or_null("Semantic")
	assert_object(semantic).is_not_null()
	var tiles = semantic.get_node_or_null("Tiles")
	assert_object(tiles).is_not_null()
	auto_free(result.runtime_room)
	if context.room:
		context.room.queue_free()


func test_bake_pipeline_handles_fatal_early_and_stops() -> void:
	var pipeline = _make_pipeline_without_save()
	var context = _make_bake_context_with_platform()

	# Inject a fatal issue before running
	context.report.add_error(BakeIssue.new(
		BakeIssue.IssueType.BAKE_FAILED,
		BakeIssue.Severity.FATAL,
		"Injected fatal",
		Vector2i.ZERO
	))

	var result = pipeline.run(context)

	assert_bool(result.report.is_has_fatal()).is_true()
	# With a fatal before any step, runtime_room should remain null
	assert_object(result.runtime_room).is_null()
	if context.room:
		context.room.queue_free()


func test_bake_pipeline_produces_room_data_with_platform_cells() -> void:
	var pipeline = _make_pipeline_without_save()
	var context = _make_bake_context_with_platform()

	pipeline.run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_int(context.runtime_room_data.platforms.size()).is_equal(1)
	auto_free(context.runtime_room)
	if context.room:
		context.room.queue_free()


func test_bake_pipeline_produces_room_data_with_wall_cells() -> void:
	var pipeline = _make_pipeline_without_save()
	var context = _make_bake_context_with_wall()

	pipeline.run(context)

	assert_bool(context.report.is_has_fatal()).is_false()
	assert_int(context.runtime_room_data.walls.size()).is_equal(1)
	auto_free(context.runtime_room)
	if context.room:
		context.room.queue_free()


# ── Runtime room structure ──────────────────────────────────────────

func test_runtime_room_has_expected_child_structure() -> void:
	var builder = RuntimeRoomBuilder.new()
	var room_data = RoomData.new()

	var room = auto_free(builder.build(room_data))

	assert_str(room.name).is_equal("RuntimeRoom")
	var semantic = room.get_node_or_null("Semantic")
	assert_object(semantic).is_not_null()
	assert_object(semantic).is_class("Node2D")
	var tiles = semantic.get_node_or_null("Tiles")
	assert_object(tiles).is_not_null()
	assert_object(tiles).is_class("TileMapLayer")


func test_runtime_room_tile_map_has_no_cells_before_theme() -> void:
	var builder = RuntimeRoomBuilder.new()
	var room_data = RoomData.new()

	var room = auto_free(builder.build(room_data))
	var tiles = room.get_node("Semantic/Tiles") as TileMapLayer

	# Before theme application the TileMapLayer should have no cells
	var used_rect = tiles.get_used_rect()
	assert_bool(used_rect.has_area()).is_false()


func test_saved_runtime_room_loads_with_expected_structure() -> void:
	var room = auto_free(
		load("res://scenes/rooms/test_scene_for_bake/test_scene_for_bake_runtime.tscn")
		.instantiate()
	)

	assert_str(room.name).is_equal("RuntimeRoom")
	var semantic = room.get_node_or_null("Semantic")
	assert_object(semantic).is_not_null()
	var tiles = semantic.get_node_or_null("Tiles")
	assert_object(tiles).is_not_null()
	assert_object(tiles).is_class("TileMapLayer")


# ── Helpers ─────────────────────────────────────────────────────────

func _make_empty_context() -> RoomBakeContext:
	var context = RoomBakeContext.new()
	context.report = BakeReport.new()
	return context


func _make_bake_context_with_platform() -> RoomBakeContext:
	var context = _make_empty_context()

	# Create a room node with a single platform brush (1×1 produces one cell)
	var room = Node2D.new()
	var brush = PlatformBrush.new()
	brush.position = Vector2(0, 0)
	brush.size = Vector2i.ONE
	room.add_child(brush)
	context.room = room
	# We own the room node; free it via the context after the test.
	# The pipeline does not free it, so we free it manually.
	context.room.set_meta("_test_free", true)

	return context


func _make_bake_context_with_wall() -> RoomBakeContext:
	var context = _make_empty_context()

	var room = Node2D.new()
	var brush = WallBrush.new()
	brush.position = Vector2(0, 0)
	brush.size = Vector2i.ONE
	room.add_child(brush)
	context.room = room
	context.room.set_meta("_test_free", true)

	return context
