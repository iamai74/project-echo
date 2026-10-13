class_name BuildStep
extends RefCounted


func get_id() -> StringName:
	return &""


func get_display_name() -> String:
	return ""


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	return context


func can_run_with_errors() -> bool:
	return true
