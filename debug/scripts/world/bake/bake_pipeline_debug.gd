extends Node

const ROOM_SCENE := preload("res://scripts/world/debug/bake_pipeline_debug.tscn")


func _ready() -> void:
	var room := ROOM_SCENE.instantiate()
	var context := RoomBakeContext.new()
	context.room = room
	var report = BakeReport.new()
	context.report = report
	var pipeline := BakePipeline.new()
	context = pipeline.run(context)
	_print_result(context)


func _print_result(context: RoomBakeContext) -> void:
	_print_summary(context)
	_print_platforms(context)
	_print_walls(context)
	_print_issues(context)


func _print_summary(context: RoomBakeContext) -> void:
	print("====== BAKE RESULT ======")
	var spatial_layers = context.semantic_data.spatial_layers
	print("Platforms: ", spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM).size())
	print("Walls: ", spatial_layers.get_cells(SpatialLayer.SpatialType.WALL).size())
	print("Background: ", spatial_layers.get_cells(SpatialLayer.SpatialType.BACKGROUND).size())


func _print_issues(context: RoomBakeContext) -> void:
	print("====== BAKE ISSUES ======")
	if context.report == null:
		print("Report is nil")
		return
	if !context.report.is_has_issues():
		print("Issues no found")
	else:
		var all_issues = context.report.get_all_issues()
		var keys = all_issues.keys() as Array[BakeIssue.IssueType]
		for key in keys:
			var issues = all_issues[key] as Array[BakeIssue]
			for issue in issues:
				print(
					BakeIssue.Severity.keys()[issue.severity],
					" ",
					BakeIssue.IssueType.keys()[issue.type],
					" ",
					issue.message,
					" ",
					issue.position
				)


func _print_platforms(context: RoomBakeContext) -> void:
	print("===== Platforms ======")
	var spatial_layers = context.semantic_data.spatial_layers
	var cells = spatial_layers.get_cells(SpatialLayer.SpatialType.PLATFORM)
	_print_cells_array(cells)


func _print_walls(context: RoomBakeContext) -> void:
	print("===== Walls ======")
	var spatial_layers = context.semantic_data.spatial_layers
	var cells = spatial_layers.get_cells(SpatialLayer.SpatialType.WALL)
	_print_cells_array(cells)


func _print_cells_array(cells: Array[SemanticSpatialCell]) -> void:
	var i: int = 1
	for cell in cells:
		var topology_cell = cell as SemanticSpatialTopologyCell
		if topology_cell != null:
			_print_topology_cell(topology_cell, i)
		var platform_cell = cell as SemanticSpatialPlatformCell
		#if platform_cell != null:
		#_print_platform_traits(platform_cell, i)
		i += 1


func _print_topology_cell(cell: SemanticSpatialTopologyCell, i: int) -> void:
	var topology = cell.topology
	if topology == null:
		print("Cell ", i, " topology is null")
		return
	print(
		"Cell ",
		i,
		" shape ",
		CellShape.Value.keys()[topology.shape],
		" corner ",
		CellCorner.Value.keys()[topology.corner]
	)


func _print_platform_traits(cell: SemanticSpatialPlatformCell, i: int) -> void:
	var traits = cell.traits
	if traits.size() == 0:
		print("Cell ", i, " without traits")
	else:
		for item in traits:
			print("Cell ", i, " ", SemanticSpatialPlatformCell.Trait.keys()[item])
