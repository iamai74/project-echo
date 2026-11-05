## Test suite for PlatformBakeProcessor.
## Covers: empty brushes, single and multi-cell brushes, traits,
## overlap detection, and non-overlapping brushes.
extends GdUnitTestSuite

func test_empty_brush_array_adds_no_cells() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brushes: Array[SemanticBrush] = []

	processor.execute(brushes, room_data)

	assert_array(room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)).has_size(0)

func test_one_by_one_brush_creates_one_cell() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(PlatformBrush.new())
	# Use a position that is aligned with tile size (32)
	brush.position = Vector2(32, 32)
	brush.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_int(cells.size()).is_equal(1)
	# Position 32 with a tile size of 32 maps to cell (1, 1).
	assert_vector(cells[0].cell).is_equal(Vector2i(1, 1))

func test_multi_cell_brush_creates_full_rectangle() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(2, 2)

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_int(cells.size()).is_equal(4)
	# Should have (0,0), (1,0), (0,1), (1,1)
	assert_vector(cells[0].cell).is_equal(Vector2i(0, 0))
	assert_vector(cells[1].cell).is_equal(Vector2i(1, 0))
	assert_vector(cells[2].cell).is_equal(Vector2i(0, 1))
	assert_vector(cells[3].cell).is_equal(Vector2i(1, 1))

func test_traits_are_copied_to_cell() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)
	brush.traits = PlatformBrush.Trait.ONE_WAY | PlatformBrush.Trait.BREAKABLE

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_int(cells.size()).is_equal(1)
	var cell := cells[0] as SemanticSpatialPlatformCell
	assert_array(cell.traits).contains(SemanticSpatialPlatformCell.Trait.ONE_WAY)
	assert_array(cell.traits).contains(SemanticSpatialPlatformCell.Trait.BREAKABLE)

func test_overlapping_brushes_emit_issue() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()

	var issues: Array[BakeIssue] = []
	processor.issue_found.connect(func(issue: BakeIssue) -> void: issues.append(issue))

	var brush1 = auto_free(PlatformBrush.new())
	brush1.position = Vector2(0, 0)
	brush1.size = Vector2i(1, 1)

	var brush2 = auto_free(PlatformBrush.new())
	brush2.position = Vector2(0, 0)
	brush2.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush1, brush2]
	processor.execute(brushes, room_data)

	assert_array(issues).has_size(1)
	assert_int(issues[0].type).is_equal(BakeIssue.IssueType.BRUSH_OVERLAP)
	assert_vector(issues[0].position).is_equal(Vector2i.ZERO)


func test_non_overlapping_brushes_emit_no_issue() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()

	var issues: Array[BakeIssue] = []
	processor.issue_found.connect(func(issue: BakeIssue) -> void: issues.append(issue))

	var brush1 = auto_free(PlatformBrush.new())
	brush1.position = Vector2(0, 0)
	brush1.size = Vector2i(1, 1)

	var brush2 = auto_free(PlatformBrush.new())
	brush2.position = Vector2(32, 0)
	brush2.size = Vector2i(1, 1)

	var brushes: Array[SemanticBrush] = [brush1, brush2]
	processor.execute(brushes, room_data)

	assert_array(issues).has_size(0)


func test_no_traits_produces_empty_trait_array() -> void:
	var processor = PlatformBakeProcessor.new()
	var room_data = SemanticRoomData.new()
	var brush = auto_free(PlatformBrush.new())
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)
	# traits default to 0, meaning no traits

	var brushes: Array[SemanticBrush] = [brush]
	processor.execute(brushes, room_data)

	var cells = room_data.spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	assert_int(cells.size()).is_equal(1)
	var cell := cells[0] as SemanticSpatialPlatformCell
	assert_int(cell.traits.size()).is_zero()
