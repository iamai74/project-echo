class_name MarkerLayer
extends RefCounted

var _layers: Dictionary = {}


func add_marker(type: MarkerType.Value, marker: MarkerData) -> void:
	if !_layers.has(type):
		var empty_markers: Array[MarkerData] = []
		_layers[type] = empty_markers
	_layers[type].append(marker)


func get_markers(type: MarkerType.Value) -> Array[MarkerData]:
	var empty_markers: Array[MarkerData] = []
	return _layers.get(type, empty_markers)


func get_all_markers() -> Array[MarkerData]:
	var all: Array[MarkerData] = []
	var known_types: Array = MarkerType.Value.values()
	for type in known_types:
		all.append_array(get_markers(type))
	for type in _layers:
		if known_types.has(type):
			continue
		var markers: Array[MarkerData] = _layers[type]
		all.append_array(markers)
	return all
