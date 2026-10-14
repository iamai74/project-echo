class_name ThemeBuilder
extends RefCounted

var _steps: Array[BuildStep]


func _init() -> void:
	_steps = [
		ThemeAssetsLoadStep.new(),
		TileSetBuildStep.new(),
		ThemeSaveStep.new(),
	]


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	for step in _steps:
		if context.report.has_fatal():
			_print_errors(context)
			break
		if not step.can_run_with_errors():
			_print_errors(context)
			break
		step.run(context)
	return context


func _print_errors(context: ThemeBuildContext) -> void:
	print("====== THEME BUILD ISSUES ======")
	if context.report == null:
		print("Report is nil")
		return
	if not context.report.has_issues():
		print("Issues not found")
	else:
		var all_issues = context.report.get_all_issues()
		var keys = all_issues.keys() as Array[ThemeBuildIssue.IssueType]
		for key in keys:
			var issues = all_issues[key] as Array[ThemeBuildIssue]
			print(ThemeBuildIssue.IssueType.keys()[key])
			for issue in issues:
				var severity = ThemeBuildIssue.Severity.keys()[issue.severity]
				print(severity, " ", issue.message)
