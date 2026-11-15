class_name RoomBounds
extends RefCounted


static func from_origin_and_size(origin: Vector2i, size: Vector2i) -> Rect2i:
	return Rect2i(origin, size)


static func has_area(bounds: Rect2i) -> bool:
	return bounds.has_area()


static func contains_cell(bounds: Rect2i, cell: Vector2i) -> bool:
	return has_area(bounds) and bounds.has_point(cell)


static func contains_rect(bounds: Rect2i, rect: Rect2i) -> bool:
	return has_area(bounds) and bounds.encloses(rect)
