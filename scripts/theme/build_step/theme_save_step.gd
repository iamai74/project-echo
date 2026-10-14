class_name ThemeSaveStep
extends BuildStep


func get_id() -> StringName:
	return &"theme_save"


func get_display_name() -> String:
	return "Save theme resources"


func run(context: ThemeBuildContext) -> ThemeBuildContext:
	var checks := [
		{"value": context.theme_tile_assets, "label": "ThemeTileAssets"},
		{"value": context.theme_info, "label": "ThemeInfo"},
		{"value": context.tileset, "label": "TileSet"},
	]

	for check in checks:
		if check["value"] == null:
			_fatal(context, "%s is null, cannot save theme" % check["label"])
			return context

	var theme_dir := context.get_resource_dir()
	var prefix := context.get_resource_prefix()

	if DirAccess.make_dir_recursive_absolute(theme_dir) != OK:
		_fatal(context, "Cannot create theme directory: " + theme_dir)
		return context

	var saves := [
		{
			"resource": context.theme_tile_assets,
			"path": prefix + "_tile_assets.tres",
		},
		{
			"resource": context.theme_info,
			"path": prefix + "_theme.tres",
		},
		{
			"resource": context.tileset,
			"path": prefix + "_tileset.tres",
		},
	]

	for save in saves:
		if ResourceSaver.save(save["resource"], save["path"]) != OK:
			_fatal(context, "Failed to save: %s" % save["path"])
			return context

	return context


func _fatal(context: ThemeBuildContext, message: String) -> void:
	context.report.add_error(
		ThemeBuildIssue.new(
			ThemeBuildIssue.IssueType.UNKNOWN,
			ThemeBuildIssue.Severity.FATAL,
			message
		)
	)
