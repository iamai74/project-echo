class_name BakePipeline
extends RefCounted

var _steps: Array[BakeStep] = []


func _init() -> void:
	var registry = _create_registry()
	var collector = _create_brush_collector()
	_steps = [
		CollectBrushesStep.new(collector),
		InitSemanticDataStep.new(),
		BakeSemanticLayerStep.new(registry),
		PostProcessStep.new()
	]


func run(context: RoomBakeContext) -> RoomBakeContext:
	for step in _steps:
		if context.report.is_has_fatal():
			_print_errors(context)
			break
		if !step.can_run_with_errors():
			_print_errors(context)
			break
		step.run(context)
	return context


func _create_brush_collector() -> BrushCollector:
	var brush_collector = BrushCollector.new()
	return brush_collector


func _create_registry() -> BakeProcessorRegistry:
	var registry = BakeProcessorRegistry.new()
	registry.register(SemanticBrush.BrushType.FLOOR, PlatformBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.WALL, WallBakeProcessor.new())
	registry.register(SemanticBrush.BrushType.BACKGROUND, BackgroundBakeProcessor.new())
	return registry


func _print_errors(context: RoomBakeContext) -> void:
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
			print(BakeIssue.IssueType.keys()[key])
			for issue in issues:
				print(
					BakeIssue.Severity.keys()[issue.severity],
					" ",
					issue.message,
					" ",
					issue.position
				)
