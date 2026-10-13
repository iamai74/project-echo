class_name ThemeBuildIssue
extends RefCounted


enum IssueType {
	UNKNOWN,
	FILE_NOT_FOUND,
	JSON_PARSE_ERROR,
	INVALID_JSON_STRUCTURE,
	INVALID_SLICE_NAME,
}

enum Severity {
	WARNING,
	ERROR,
	FATAL,
}


var type: IssueType
var severity: Severity
var message: String


func _init(p_type: IssueType, p_severity: Severity, p_message: String) -> void:
	type = p_type
	severity = p_severity
	message = p_message
