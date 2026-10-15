class_name ApplyDefaultThemeStep
extends BakeStep


const DEFAULT_THEME_PATH := "res://resources/themes/default/default_theme.tres"


func get_id() -> StringName:
	return &"apply_default_theme"


func get_display_name() -> String:
	return "ApplyDefaultThemeStep"


func run(context: RoomBakeContext) -> RoomBakeContext:
	if context.runtime_room == null:
		context.report.add_error(_error(
			BakeIssue.IssueType.SEVERE_DATA_LOSS,
			"Runtime room node is null, cannot apply theme"
		))
		return context

	if context.runtime_room_data == null:
		context.report.add_error(_error(
			BakeIssue.IssueType.SEVERE_DATA_LOSS,
			"Runtime room data is null, cannot apply theme"
		))
		return context

	var theme := load(DEFAULT_THEME_PATH) as ThemeInfo
	if theme == null:
		context.report.add_error(_error(
			BakeIssue.IssueType.BAKE_FAILED,
			"Failed to load default theme from %s" % DEFAULT_THEME_PATH
		))
		return context

	var applyer := ThemeApplyer.new()
	applyer.apply(context.runtime_room, theme, context.runtime_room_data)

	return context


func _error(issue_type: BakeIssue.IssueType, message: String) -> BakeIssue:
	return BakeIssue.new(issue_type, BakeIssue.Severity.FATAL, message, Vector2i.ZERO)
