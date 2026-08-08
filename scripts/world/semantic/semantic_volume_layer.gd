class_name VolumeLayer
extends RefCounted

enum VolumeType {
	MUSIC_ZONE,
	LIGHT_ZONE
}

var _layers: Dictionary = {}


func add_item(type: VolumeType, item: SemanticVolume) -> void:
	if !_layers.has(type):
		_layers[type] = []
	_layers[type].append(item)


func get_items(type: VolumeType) -> Array[SemanticVolume]:
	return _layers.get(type, [])
