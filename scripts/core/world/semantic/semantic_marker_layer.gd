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
		_layers[type] = []
	_layers[type].append(marker)

func get_markers(type: MarkerType) -> Array[SemanticMarker]:
	return _layers.get(type, [])
