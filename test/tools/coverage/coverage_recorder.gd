extends Node

var _hits: Dictionary = {}
var _output_path: String = ""
var _written: bool = false


func _ready() -> void:
	_output_path = OS.get_environment("ECHO_COVERAGE_OUTPUT")
	process_mode = Node.PROCESS_MODE_ALWAYS


func hit(file_path: String, line: int) -> void:
	var lines: Dictionary = _hits.get(file_path, {})
	lines[line] = true
	_hits[file_path] = lines


func _exit_tree() -> void:
	_write()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_write()


func _write() -> void:
	if _written or _output_path.is_empty():
		return
	_written = true

	var payload := {}
	for file_path in _hits:
		var lines: Array = _hits[file_path].keys()
		lines.sort()
		payload[file_path] = lines

	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		push_error("CoverageRecorder: cannot write coverage output to ", _output_path)
		return

	file.store_string(JSON.stringify({"hits": payload}))
	file.close()
