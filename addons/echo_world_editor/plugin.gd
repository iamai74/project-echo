## Entry point for the Echo World Editor addon.
##
## Godot instantiates this `EditorPlugin` when the addon is enabled and calls
## `_enter_tree()` / `_exit_tree()` for lifecycle management. The plugin is a
## thin wrapper: it owns an `EditorContext` and an `EchoWorldEditorDock`,
## registers the dock, refreshes the context when the edited scene changes, and
## releases both on disable. It never creates or modifies nodes in the edited
## scene.
@tool
class_name EchoWorldEditorPlugin
extends EditorPlugin

const EditorDockScene: PackedScene = preload("res://addons/echo_world_editor/ui/editor_dock.tscn")

var context: EditorContext = null
var dock: EchoWorldEditorDock = null


func _enter_tree() -> void:
	context = EditorContext.new()
	dock = EditorDockScene.instantiate() as EchoWorldEditorDock
	dock.title = EchoWorldEditorDock.TITLE
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL

	add_dock(dock)

	# Scene changes arrive through EditorPlugin signals, not a virtual callback:
	# `scene_changed` for the scene that just became active and `scene_closed`
	# for a closed one.
	scene_changed.connect(_on_scene_changed)
	scene_closed.connect(_on_scene_closed)

	# Classify the scene that is open at enable time so the dock shows the
	# initial status immediately.
	context.refresh(get_editor_interface())
	dock.set_context(context)


func _exit_tree() -> void:
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if scene_closed.is_connected(_on_scene_closed):
		scene_closed.disconnect(_on_scene_closed)

	# `remove_dock()` only unregisters the dock; freeing it stays with the plugin.
	if dock != null:
		remove_dock(dock)
		dock.queue_free()

	dock = null
	context = null


func _on_scene_changed(scene_root: Node) -> void:
	if scene_root != null:
		_apply_scene_root(scene_root)
		return
	# A new empty scene reports a null root; read the editor once the change has
	# settled so the root that actually opened is classified.
	_refresh_from_editor.call_deferred()


func _on_scene_closed(_filepath: String) -> void:
	# Another scene may become active, or none; read the editor after the close
	# has settled instead of assuming either outcome.
	_refresh_from_editor.call_deferred()


func _apply_scene_root(root: Node) -> void:
	if context == null or dock == null:
		return
	context.apply_edited_scene_root(root)
	dock.set_context(context)


func _refresh_from_editor() -> void:
	if context == null or dock == null:
		return
	context.refresh(get_editor_interface())
	dock.set_context(context)
