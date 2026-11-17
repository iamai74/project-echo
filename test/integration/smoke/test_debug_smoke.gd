## Debug smoke tests.
## Covers: instantiating the debug enemy subclasses (Runner, Heavy) and the
## playable entry scene without crashing, and asserting each root is non-null.
extends GdUnitTestSuite


func test_runner_scene_instantiates() -> void:
	var scene := load("res://debug/actors/enemies/runner.tscn") as PackedScene
	var root: Node = auto_free(scene.instantiate())
	add_child(root)
	assert_object(root).is_not_null()


func test_heavy_scene_instantiates() -> void:
	var scene := load("res://debug/actors/enemies/heavy.tscn") as PackedScene
	var root: Node = auto_free(scene.instantiate())
	add_child(root)
	assert_object(root).is_not_null()


func test_playable_entry_scene_instantiates() -> void:
	var scene := load("res://debug/scenes/test_scene.tscn") as PackedScene
	var root: Node = auto_free(scene.instantiate())
	add_child(root)
	assert_object(root).is_not_null()
