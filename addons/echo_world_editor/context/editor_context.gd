## Tracks the scene currently open in the Godot editor and classifies it as an
## authoring room, an unsupported scene, or no scene at all.
##
## Plain, editor-independent object: it holds no scene nodes and never modifies
## the edited scene. It only reads the edited scene root through the editor
## interface, so it can be instantiated and tested in isolation.
class_name EditorContext
extends RefCounted

const STATUS_NO_SCENE := "No scene"
const STATUS_AUTHORING := "Authoring room"
const STATUS_UNSUPPORTED := "Unsupported scene"

## Root node of the currently edited scene, or null when none is open.
var current_scene_root: Node = null

## File path of the currently edited scene, or empty when none is open.
var current_scene_path: String = ""

## True when the edited scene root carries the RoomAuthoring script.
var is_authoring: bool = false

## Human-readable summary of the current scene classification.
var status: String = STATUS_NO_SCENE


## Classifies the scene currently open in the editor and updates this context.
##
## No scene is created or modified; the edited scene root is only read.
func refresh(editor_interface: EditorInterface) -> void:
	apply_edited_scene_root(editor_interface.get_edited_scene_root())


## Classifies an edited-scene root and updates this context's state.
##
## This is the editor-independent half of refresh(): it performs the whole
## classification without touching the editor interface, so it can be driven by
## controllable, editor-independent nodes in headless unit tests. refresh() reads
## the root from the interface and delegates here. No scene is created or
## modified; the root is only read.
func apply_edited_scene_root(root: Node) -> void:
	current_scene_root = root

	if root == null:
		is_authoring = false
		current_scene_path = ""
		status = STATUS_NO_SCENE
		return

	current_scene_path = root.get_scene_file_path()

	if root is RoomAuthoring:
		is_authoring = true
		status = STATUS_AUTHORING
	else:
		is_authoring = false
		status = STATUS_UNSUPPORTED
