class_name BrushCollector


func collect(root: Node) -> BrushCollection:
	var collection = BrushCollection.new()
	_collect_recursive(root, collection)
	return collection


func _collect_recursive(node: Node, collection: BrushCollection) -> void:
	if node is SemanticBrush:
		collection.add_brush(node)

	for child in node.get_children():
		_collect_recursive(child, collection)
