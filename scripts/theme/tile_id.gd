class_name TileId
extends Resource

@export var source_id: int
@export var atlas_coords: Vector2i


func _init(p_source_id: int = 0, p_atlas_coords: Vector2i = Vector2i.ZERO) -> void:
	source_id = p_source_id
	atlas_coords = p_atlas_coords


static func at_source(source_id: int, atlas_coords: Vector2i) -> TileId:
	return TileId.new(source_id, atlas_coords)
