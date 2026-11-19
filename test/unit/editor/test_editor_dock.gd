## EditorDock tests.
##
## An EditorDock can only be instantiated by the editor, so the on-screen dock
## cannot be built in a headless run; the editor-GUI verification (add_dock +
## live label updates) is covered by the Foundation plan's Task 10. Headless,
## we can still prove the scene loads without errors and that the status-text
## logic set_context/clear rely on is correct.
extends GdUnitTestSuite

const DOCK_SCENE_PATH: String = "res://addons/echo_world_editor/ui/editor_dock.tscn"


## The scene must load via ResourceLoader without errors.
func test_scene_loads_without_errors() -> void:
	var scene: PackedScene = ResourceLoader.load(DOCK_SCENE_PATH)
	assert_object(scene).is_not_null()
	assert_bool(scene is PackedScene).is_true()


## A null context (and therefore clear()) yields the "No scene" status.
func test_status_text_null_context_is_no_scene() -> void:
	assert_str(EchoWorldEditorDock.status_text(null)).is_equal(EditorContext.STATUS_NO_SCENE)


## An authoring context with a path shows status plus the path.
func test_status_text_authoring_with_path() -> void:
	var context = EditorContext.new()
	context.is_authoring = true
	context.status = EditorContext.STATUS_AUTHORING
	context.current_scene_path = "res://scenes/rooms/test_room.tscn"

	assert_str(
		EchoWorldEditorDock.status_text(context)
	).is_equal("Authoring room — res://scenes/rooms/test_room.tscn")


## A context with no path shows only its status text.
func test_status_text_status_only_without_path() -> void:
	var context = EditorContext.new()
	context.is_authoring = false
	context.status = EditorContext.STATUS_UNSUPPORTED

	assert_str(EchoWorldEditorDock.status_text(context)).is_equal(EditorContext.STATUS_UNSUPPORTED)
