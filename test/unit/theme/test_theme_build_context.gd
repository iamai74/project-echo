## ThemeBuildContext unit tests.
## Covers: path formatting for resource dir and prefix.
extends GdUnitTestSuite


func test_get_resource_dir_formats_theme_name() -> void:
	var context = ThemeBuildContext.new()
	context.theme_name = "default"

	var dir = context.get_resource_dir()
	assert_str(dir).contains("default")
	assert_str(dir).contains("res://resources/themes/")


func test_get_resource_prefix_includes_theme_name() -> void:
	var context = ThemeBuildContext.new()
	context.theme_name = "cave"

	var prefix = context.get_resource_prefix()
	# The prefix is resource_dir + theme_name
	assert_str(prefix).contains("cave")


func test_context_fields_are_accessible() -> void:
	var context = ThemeBuildContext.new()
	context.theme_name = "test_theme"
	assert_str(context.theme_name).is_equal("test_theme")
