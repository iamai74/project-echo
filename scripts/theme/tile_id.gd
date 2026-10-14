class_name TileId
extends RefCounted

var source_id: int
var atlas_coords: Vector2i

func _init(p_source_id: int, p_atlas_coords: Vector2i) -> void:
	source_id = p_source_id
	atlas_coords = p_atlas_coords


static func at_source(source_id: int, atlas_coords: Vector2i) -> TileId:
	return TileId.new(source_id, atlas_coords)
