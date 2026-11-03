## BrushCollection unit tests.
## Covers: add brushes, get brushes by type, unknown brush ignored, empty collection.
extends GdUnitTestSuite


class MockSemanticBrush:
	extends SemanticBrush
	var _type: SemanticBrush.BrushType

	func _init(type: SemanticBrush.BrushType) -> void:
		_type = type

	func get_brush_type() -> SemanticBrush.BrushType:
		return _type


func test_empty_collection_returns_empty_array() -> void:
	var collection = BrushCollection.new()
	var brushes = collection.get_brushes(SemanticBrush.BrushType.PLATFORM)
	assert_int(brushes.size()).is_zero()


func test_add_brush_groups_by_type() -> void:
	var collection = BrushCollection.new()
	var brush1 = auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.PLATFORM))
	var brush2 = auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.PLATFORM))
	var brush3 = auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.WALL))

	collection.add_brush(brush1)
	collection.add_brush(brush2)
	collection.add_brush(brush3)

	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(2)
	assert_int(collection.get_brushes(SemanticBrush.BrushType.WALL).size()).is_equal(1)


func test_add_unknown_brush_is_ignored() -> void:
	var collection = BrushCollection.new()
	var unknown = auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.UNKNOWN))
	collection.add_brush(unknown)

	# UNKNOWN brushes should not be stored
	var all_platforms = collection.get_brushes(SemanticBrush.BrushType.PLATFORM)
	var all_walls = collection.get_brushes(SemanticBrush.BrushType.WALL)
	var all_bg = collection.get_brushes(SemanticBrush.BrushType.BACKGROUND)
	assert_int(all_platforms.size()).is_zero()
	assert_int(all_walls.size()).is_zero()
	assert_int(all_bg.size()).is_zero()


func test_get_brushes_returns_empty_for_unregistered_type() -> void:
	var collection = BrushCollection.new()
	var brush = auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.PLATFORM))
	collection.add_brush(brush)

	var walls = collection.get_brushes(SemanticBrush.BrushType.WALL)
	assert_int(walls.size()).is_zero()


func test_add_multiple_types_independently() -> void:
	var collection = BrushCollection.new()
	collection.add_brush(auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.PLATFORM)))
	collection.add_brush(auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.WALL)))
	collection.add_brush(auto_free(MockSemanticBrush.new(SemanticBrush.BrushType.BACKGROUND)))

	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)
	assert_int(collection.get_brushes(SemanticBrush.BrushType.WALL).size()).is_equal(1)
	assert_int(collection.get_brushes(SemanticBrush.BrushType.BACKGROUND).size()).is_equal(1)
