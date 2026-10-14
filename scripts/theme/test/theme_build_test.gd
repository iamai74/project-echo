extends Node

const THEME_NAME := "default"

const PACK_FIELDS := [
	"single",
	"single_all",
	"single_top",
	"single_bottom",
	"single_left",
	"single_right",
	"top",
	"bottom",
	"left",
	"right",
	"full",
	"top_left",
	"top_right",
	"bottom_left",
	"bottom_right",
]


func _ready() -> void:
	var context := ThemeBuildContext.new()
	context.theme_name = THEME_NAME
	context.report = ThemeBuildReport.new()
	var builder := ThemeBuilder.new()
	context = builder.run(context)
	_print_result(context)


func _print_result(context: ThemeBuildContext) -> void:
	_print_summary(context)
	_print_issues(context)


func _print_summary(context: ThemeBuildContext) -> void:
	print("====== THEME BUILD RESULT ======")
	print("Theme: ", context.theme_name)
	if context.tileset == null:
		print("TileSet: not built")
	else:
		print("TileSet sources: ", context.tileset.get_source_count())
	if context.theme_info == null:
		print("ThemeInfo: not built")
	else:
		print("TileSet resource: ", context.theme_info.tileset)
		print("Platforms: ", _count_pack(context.theme_info.platforms))
		print("Walls: ", _count_pack(context.theme_info.walls))
		print("Background: ", context.theme_info.background.size())


func _count_pack(pack: TilePack) -> int:
	if pack == null:
		return 0
	var total := 0
	for field in PACK_FIELDS:
		total += (pack.get(field) as Array).size()
	return total


func _print_issues(context: ThemeBuildContext) -> void:
	print("====== THEME BUILD ISSUES ======")
	if context.report == null:
		print("Report is nil")
		return
	if not context.report.has_issues():
		print("Issues not found")
		return
	var all_issues := context.report.get_all_issues()
	for key in all_issues.keys():
		var issues := all_issues[key] as Array
		for issue: ThemeBuildIssue in issues:
			print(
				ThemeBuildIssue.Severity.keys()[issue.severity],
				" ",
				ThemeBuildIssue.IssueType.keys()[issue.type],
				" ",
				issue.message
			)
