class_name BakeReport
extends RefCounted

var _issues: Dictionary = {}


func add_issue(issue: BakeIssue) -> void:
	if not _issues.has(issue.type):
		_issues[issue.type] = []
	_issues[issue.type].append(issue)


func add_error(error: BakeIssue) -> void:
	add_issue(error)


func add_warning(warning: BakeIssue) -> void:
	add_issue(warning)


func is_has_saverity(saverity: BakeIssue.Severity) -> bool:
	for key in _issues.keys():
		for item in _issues[key]:
			var issue = item as BakeIssue
			if issue.severity == saverity:
				return true
	return false


func is_has_fatal() -> bool:
	return is_has_saverity(BakeIssue.Severity.FATAL)


func is_has_issues() -> bool:
	return !_issues.is_empty()


func get_all_issues() -> Dictionary:
	return _issues
