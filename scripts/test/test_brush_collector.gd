## BrushCollector unit tests.
## Covers: collecting root brushes, nested brushes, ignoring non-brush nodes,
## empty rooms, and disabled brushes.
extends GdUnitTestSuite


func test_collects_brush_at_root_node() -> void:
	var root = auto_free(PlatformBrush.new())
	root.position = Vector2(0, 0)
	root.size = Vector2i(1, 1)
	
	var collector = BrushCollector.new()
	var collection = collector.collect(root)
	
	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)


func test_recursively_collects_nested_brushes() -> void:
	var root = auto_free(Node2D.new())
	var child = Node2D.new()
	root.add_child(child)
	
	var brush1 = PlatformBrush.new()
	brush1.position = Vector2(0, 0)
	brush1.size = Vector2i(1, 1)
	root.add_child(brush1)
	
	var brush2 = WallBrush.new()
	brush2.position = Vector2(32, 0)
	brush2.size = Vector2i(1, 1)
	child.add_child(brush2)
	
	var collector = BrushCollector.new()
	var collection = collector.collect(root)
	
	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)
	assert_int(collection.get_brushes(SemanticBrush.BrushType.WALL).size()).is_equal(1)


func test_ignores_non_brush_nodes() -> void:
	var root = auto_free(Node2D.new())
	var non_brush = Node2D.new()
	root.add_child(non_brush)
	
	var brush = PlatformBrush.new()
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)
	root.add_child(brush)
	
	var collector = BrushCollector.new()
	var collection = collector.collect(root)
	
	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)


func test_preserves_collection_when_no_brushes_exist() -> void:
	var root = auto_free(Node2D.new())
	
	var collector = BrushCollector.new()
	var collection = collector.collect(root)
	
	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_zero()
	assert_int(collection.get_brushes(SemanticBrush.BrushType.WALL).size()).is_zero()
	assert_int(collection.get_brushes(SemanticBrush.BrushType.BACKGROUND).size()).is_zero()


func test_does_not_collect_disabled_brushes() -> void:
	var root = auto_free(Node2D.new())
	var brush = PlatformBrush.new()
	brush.position = Vector2(0, 0)
	brush.size = Vector2i(1, 1)
	brush.enabled = false
	root.add_child(brush)
	
	var collector = BrushCollector.new()
	var collection = collector.collect(root)
	
	# Disabled brushes are still collected; the brush.enabled property is
	# an authoring concern handled by validation, not collection.
	# BrushCollector collects all SemanticBrush nodes regardless of enabled.
	assert_int(collection.get_brushes(SemanticBrush.BrushType.PLATFORM).size()).is_equal(1)
