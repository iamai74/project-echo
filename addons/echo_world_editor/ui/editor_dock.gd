## Minimal EditorDock for the Echo World Editor.
##
## Displays the addon title and the current editor context status. It holds no
## dependency on EditorPlugin: the editor context is passed in through
## set_context(), so the dock can be instantiated and inspected in isolation.
##
## The dock is display-only for the Foundation milestone: it has no buttons,
## brush controls, inspector integration, or bake UI.
##
## Marked `@tool` so the script runs in the editor: the plugin instantiates this
## dock and calls its methods from a tool context, which requires a tool script
## (otherwise the methods run on a placeholder instance).
@tool
class_name EchoWorldEditorDock
extends EditorDock

const TITLE: String = "Echo World Editor"

const TITLE_LABEL_PATH: String = "VBoxContainer/title_label"
const STATUS_LABEL_PATH: String = "VBoxContainer/status_label"


## Sets the title and status labels from the given context.
##
## A null context produces the same "No scene" state as clear().
func set_context(context: EditorContext) -> void:
	var title_label: Label = get_node_or_null(TITLE_LABEL_PATH)
	var status_label: Label = get_node_or_null(STATUS_LABEL_PATH)
	if title_label == null or status_label == null:
		return
	title_label.text = TITLE
	status_label.text = status_text(context)


## Resets the dock to the "No scene" state, clearing any scene path.
func clear() -> void:
	set_context(null)


## Builds the status label text from a context, falling back to "No scene".
##
## Static so the text formatting is testable in isolation: an EditorDock can only
## be instantiated by the editor, so it cannot be built in a headless test.
static func status_text(context: EditorContext) -> String:
	if context == null:
		return EditorContext.STATUS_NO_SCENE
	var path: String = context.current_scene_path
	if path.is_empty():
		return context.status
	return "%s — %s" % [context.status, path]
