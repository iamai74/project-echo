## BakeProcessorRegistry unit tests.
## Covers: register, get_processor, get_types, missing processor returns null.
extends GdUnitTestSuite


func test_register_and_get_processor() -> void:
	var registry = BakeProcessorRegistry.new()
	var mock_processor = BakeProcessor.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, mock_processor)

	var retrieved = registry.get_processor(SemanticBrush.BrushType.PLATFORM)
	assert_object(retrieved).is_not_null()
	assert_bool(retrieved == mock_processor).is_true()


func test_get_processor_returns_null_for_unknown_type() -> void:
	var registry = BakeProcessorRegistry.new()

	var retrieved = registry.get_processor(SemanticBrush.BrushType.UNKNOWN)
	assert_object(retrieved).is_null()


func test_get_types_returns_registered_types() -> void:
	var registry = BakeProcessorRegistry.new()
	registry.register(SemanticBrush.BrushType.PLATFORM, BakeProcessor.new())
	registry.register(SemanticBrush.BrushType.WALL, BakeProcessor.new())

	var types = registry.get_types()
	assert_int(types.size()).is_equal(2)
	assert_bool(types.has(SemanticBrush.BrushType.PLATFORM)).is_true()
	assert_bool(types.has(SemanticBrush.BrushType.WALL)).is_true()


func test_get_types_returns_empty_when_nothing_registered() -> void:
	var registry = BakeProcessorRegistry.new()

	var types = registry.get_types()
	assert_int(types.size()).is_zero()


func test_register_overwrites_existing() -> void:
	var registry = BakeProcessorRegistry.new()
	var first = BakeProcessor.new()
	var second = BakeProcessor.new()

	registry.register(SemanticBrush.BrushType.PLATFORM, first)
	registry.register(SemanticBrush.BrushType.PLATFORM, second)

	var retrieved = registry.get_processor(SemanticBrush.BrushType.PLATFORM)
	assert_bool(retrieved == second).is_true()
