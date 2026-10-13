class_name ThemeBuildReport
extends RefCounted


var _issues: Dictionary = {}


func add_issue(issue: ThemeBuildIssue) -> void:
	if not _issues.has(issue.type):
		_issues[issue.type] = []
	_issues[issue.type].append(issue)


func add_error(error: ThemeBuildIssue) -> void:
	add_issue(error)


func add_warning(warning: ThemeBuildIssue) -> void:
	add_issue(warning)


func has_severity(severity: ThemeBuildIssue.Severity) -> bool:
	for key in _issues.keys():
		for item in _issues[key]:
			var issue = item as ThemeBuildIssue
			if issue.severity == severity:
				return true
	return false


func has_fatal() -> bool:
	return has_severity(ThemeBuildIssue.Severity.FATAL)


func has_issues() -> bool:
	return !_issues.is_empty()


func get_all_issues() -> Dictionary:
	return _issues
