## BakeReport unit tests.
## Covers: issue grouping, severity queries, fatal detection, empty report.
extends GdUnitTestSuite


var report: BakeReport


func before_test() -> void:
	report = BakeReport.new()


func test_empty_report_has_no_issues() -> void:
	assert_bool(report.is_has_issues()).is_false()
	assert_bool(report.is_has_fatal()).is_false()
	assert_bool(report.is_has_saverity(BakeIssue.Severity.ERROR)).is_false()
	assert_bool(report.is_has_saverity(BakeIssue.Severity.WARNING)).is_false()


func test_add_issue_tracks_issue() -> void:
	var issue = BakeIssue.new(
		BakeIssue.IssueType.BRUSH_INVALID,
		BakeIssue.Severity.WARNING,
		"Test warning",
		Vector2i(0, 0)
	)
	report.add_issue(issue)
	assert_bool(report.is_has_issues()).is_true()


func test_add_error_tracks_issue() -> void:
	var issue = BakeIssue.new(
		BakeIssue.IssueType.BAKE_FAILED,
		BakeIssue.Severity.ERROR,
		"Test error",
		Vector2i(1, 1)
	)
	report.add_error(issue)
	assert_bool(report.is_has_saverity(BakeIssue.Severity.ERROR)).is_true()


func test_add_warning_tracks_issue() -> void:
	var issue = BakeIssue.new(
		BakeIssue.IssueType.BRUSH_INVALID,
		BakeIssue.Severity.WARNING,
		"Test warning",
		Vector2i(2, 2)
	)
	report.add_warning(issue)
	assert_bool(report.is_has_saverity(BakeIssue.Severity.WARNING)).is_true()


func test_fatal_detection() -> void:
	var fatal = BakeIssue.new(
		BakeIssue.IssueType.SEVERE_DATA_LOSS,
		BakeIssue.Severity.FATAL,
		"Fatal issue",
		Vector2i(0, 0)
	)
	report.add_issue(fatal)
	assert_bool(report.is_has_fatal()).is_true()


func test_no_fatal_without_fatal_issue() -> void:
	var warning = BakeIssue.new(
		BakeIssue.IssueType.BRUSH_INVALID,
		BakeIssue.Severity.WARNING,
		"Just a warning",
		Vector2i(0, 0)
	)
	var error = BakeIssue.new(
		BakeIssue.IssueType.BRUSH_OVERLAP,
		BakeIssue.Severity.ERROR,
		"An error",
		Vector2i(1, 1)
	)
	report.add_issue(warning)
	report.add_issue(error)
	assert_bool(report.is_has_fatal()).is_false()
	assert_bool(report.is_has_saverity(BakeIssue.Severity.ERROR)).is_true()
	assert_bool(report.is_has_saverity(BakeIssue.Severity.WARNING)).is_true()


func test_issue_grouping_by_type() -> void:
	report.add_issue(
		BakeIssue.new(BakeIssue.IssueType.BRUSH_INVALID, BakeIssue.Severity.WARNING, "w1", Vector2i(0, 0))
	)
	report.add_issue(
		BakeIssue.new(BakeIssue.IssueType.BRUSH_INVALID, BakeIssue.Severity.WARNING, "w2", Vector2i(1, 0))
	)
	report.add_issue(
		BakeIssue.new(BakeIssue.IssueType.BRUSH_OVERLAP, BakeIssue.Severity.ERROR, "e1", Vector2i(0, 1))
	)
	var all = report.get_all_issues()
	assert_int(all[BakeIssue.IssueType.BRUSH_INVALID].size()).is_equal(2)
	assert_int(all[BakeIssue.IssueType.BRUSH_OVERLAP].size()).is_equal(1)


func test_get_all_issues_returns_dictionary() -> void:
	assert_bool(report.get_all_issues() is Dictionary).is_true()


func test_issue_stores_position() -> void:
	var position = Vector2i(5, 10)
	var issue = BakeIssue.new(
		BakeIssue.IssueType.BRUSH_INVALID,
		BakeIssue.Severity.WARNING,
		"position test",
		position
	)
	report.add_issue(issue)
	var all = report.get_all_issues()
	var stored = all[BakeIssue.IssueType.BRUSH_INVALID][0]
	assert_vector(stored.position).is_equal(position)
