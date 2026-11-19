## EditorContext unit tests.
##
## EditorContext classifies the scene the editor is currently editing: a
## RoomAuthoring root is an authoring room, any other node root is an
## unsupported scene, and a null root means no scene is open.
##
## The interface-reading half of that — refresh(editor_interface) — depends on
## the editor-only EditorInterface singleton, which cannot be instantiated or
## faked outside the running editor: its runtime type check rejects any stand-in,
## and it cannot be controlled in a headless run. That path is covered by the
## Foundation plan's Task 10 manual editor verification.
##
## These tests drive the editor-independent classification through
## apply_edited_scene_root() — the exact rule refresh() delegates to — with real,
## controllable roots, following the project's headless-test convention (see
## test/unit/editor/test_editor_dock.gd, which tests the dock's extracted
## status_text() helper).
extends GdUnitTestSuite


# --- No scene ---

## A freshly created context reports "No scene": no root, not authoring, empty
## path. This is the initial state refresh() leaves the context in when the
## edited scene root is null.
func test_default_state_is_no_scene() -> void:
	var context = EditorContext.new()

	assert_object(context.current_scene_root).is_null()
	assert_str(context.current_scene_path).is_equal("")
	assert_bool(context.is_authoring).is_false()
	assert_str(context.status).is_equal(EditorContext.STATUS_NO_SCENE)


## A null root classifies as "No scene": not authoring, with the path cleared.
func test_null_root_is_classified_as_no_scene() -> void:
	var context = EditorContext.new()

	context.apply_edited_scene_root(null)

	assert_object(context.current_scene_root).is_null()
	assert_str(context.current_scene_path).is_equal("")
	assert_bool(context.is_authoring).is_false()
	assert_str(context.status).is_equal(EditorContext.STATUS_NO_SCENE)


# --- Authoring room ---

## A scene root that carries the RoomAuthoring script is classified as an
## authoring room.
func test_room_authoring_root_is_classified_as_authoring() -> void:
	var root = RoomAuthoring.new()
	# Sanity: the root we feed really is a RoomAuthoring, the predicate the rule
	# keys on.
	assert_bool(root is RoomAuthoring).is_true()

	var context = EditorContext.new()
	context.apply_edited_scene_root(root)

	assert_object(context.current_scene_root).is_not_null()
	assert_bool(context.is_authoring).is_true()
	assert_str(context.status).is_equal(EditorContext.STATUS_AUTHORING)

	root.free()


# --- Unsupported scene ---

## A scene root that is not a RoomAuthoring is classified as an unsupported
## scene.
func test_plain_node2d_root_is_classified_as_unsupported() -> void:
	var root = Node2D.new()
	# Sanity: the root we feed is not a RoomAuthoring.
	assert_bool(root is RoomAuthoring).is_false()

	var context = EditorContext.new()
	context.apply_edited_scene_root(root)

	assert_object(context.current_scene_root).is_not_null()
	assert_bool(context.is_authoring).is_false()
	assert_str(context.status).is_equal(EditorContext.STATUS_UNSUPPORTED)

	root.free()


# --- Constants ---

## The status constants carry the documented human-readable strings.
func test_status_constants_have_expected_values() -> void:
	assert_str(EditorContext.STATUS_NO_SCENE).is_equal("No scene")
	assert_str(EditorContext.STATUS_AUTHORING).is_equal("Authoring room")
	assert_str(EditorContext.STATUS_UNSUPPORTED).is_equal("Unsupported scene")
