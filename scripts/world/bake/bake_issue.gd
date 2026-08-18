class_name BakeIssue
extends RefCounted

enum IssueType {
	UNKNOWN,
	BRUSH_INVALID,
	BRUSH_OVERLAP,
	SEMANTIC_CONFLICT,
	BAKE_FAILED,
}
enum Severity {
	WARNING,
	ERROR,
	FATAL,
}

var type: IssueType
var severity: Severity
var message: String
var position: Vector2i


func _init(type: IssueType, severity: Severity, message: String, position: Vector2i) -> void:
	self.type = type
	self.severity = severity
	self.message = message
	self.position = position
