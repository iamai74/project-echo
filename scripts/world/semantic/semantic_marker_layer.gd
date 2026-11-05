class_name MarkerLayer
extends RefCounted

enum MarkerType {
	ENEMY_SPAWN,
	LOOT_SPAWN,
	CHECKPOINT
}

var _layers: Dictionary = {}


func add_marker(type: MarkerType, marker: SemanticMarker) -> void:
	if !_layers.has(type):
		var empty_markers: Array[SemanticMarker] = []
		_layers[type] = empty_markers
	_layers[type].append(marker)


func get_markers(type: MarkerType) -> Array[SemanticMarker]:
	var empty_markers: Array[SemanticMarker] = []
	return _layers.get(type, empty_markers)
