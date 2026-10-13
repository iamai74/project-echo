class_name ThemeBuilder
extends RefCounted

var _steps: Array[BuildStep]


func _init() -> void:
	_steps = []


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	for step in _steps:
		step.run(context)
	return context
