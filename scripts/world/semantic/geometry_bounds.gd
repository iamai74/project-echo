class_name GeometryBounds
extends RefCounted


static func compute(spatial_layers: SpatialLayer) -> Rect2i:
	var cells: Array[SemanticSpatialCell] = []
	cells.append_array(spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM))
	cells.append_array(spatial_layers.get_cells(SpatialLayer.SpatialType.WALL))
	return from_cells(cells)


static func from_cells(cells: Array[SemanticSpatialCell]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()

	var min_pos = cells[0].cell
	var max_pos = cells[0].cell
	for cell in cells:
		min_pos.x = min(min_pos.x, cell.cell.x)
		min_pos.y = min(min_pos.y, cell.cell.y)
		max_pos.x = max(max_pos.x, cell.cell.x)
		max_pos.y = max(max_pos.y, cell.cell.y)

	var size = (max_pos - min_pos) + Vector2i.ONE
	return Rect2i(min_pos, size)


static func has_area(bounds: Rect2i) -> bool:
	return bounds.has_area()
