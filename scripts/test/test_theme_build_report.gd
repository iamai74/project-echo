## ThemeBuildReport unit tests.
## Covers: warnings vs errors vs fatal, grouping, empty report.
extends GdUnitTestSuite


var report: ThemeBuildReport


func before_test() -> void:
	report = ThemeBuildReport.new()


func test_empty_report_has_no_issues() -> void:
	assert_bool(report.has_issues()).is_false()
	assert_bool(report.has_fatal()).is_false()
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.ERROR)).is_false()
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.WARNING)).is_false()


func test_add_issue_tracks_issue() -> void:
	var issue = ThemeBuildIssue.new(
		ThemeBuildIssue.IssueType.FILE_NOT_FOUND,
		ThemeBuildIssue.Severity.WARNING,
		"Missing file"
	)
	report.add_issue(issue)
	assert_bool(report.has_issues()).is_true()


func test_add_error_tracks_issue() -> void:
	var issue = ThemeBuildIssue.new(
		ThemeBuildIssue.IssueType.JSON_PARSE_ERROR,
		ThemeBuildIssue.Severity.ERROR,
		"Bad JSON"
	)
	report.add_error(issue)
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.ERROR)).is_true()


func test_add_warning_tracks_issue() -> void:
	var issue = ThemeBuildIssue.new(
		ThemeBuildIssue.IssueType.INVALID_SLICE_NAME,
		ThemeBuildIssue.Severity.WARNING,
		"Odd name"
	)
	report.add_warning(issue)
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.WARNING)).is_true()


func test_fatal_detection() -> void:
	var fatal = ThemeBuildIssue.new(
		ThemeBuildIssue.IssueType.UNKNOWN,
		ThemeBuildIssue.Severity.FATAL,
		"Fatal theme build error"
	)
	report.add_issue(fatal)
	assert_bool(report.has_fatal()).is_true()


func test_no_fatal_without_fatal_issue() -> void:
	report.add_issue(
		ThemeBuildIssue.new(ThemeBuildIssue.IssueType.FILE_NOT_FOUND, ThemeBuildIssue.Severity.WARNING, "w1")
	)
	report.add_issue(
		ThemeBuildIssue.new(ThemeBuildIssue.IssueType.JSON_PARSE_ERROR, ThemeBuildIssue.Severity.ERROR, "e1")
	)
	assert_bool(report.has_fatal()).is_false()
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.ERROR)).is_true()
	assert_bool(report.has_severity(ThemeBuildIssue.Severity.WARNING)).is_true()


func test_issue_grouping_by_type() -> void:
	report.add_issue(
		ThemeBuildIssue.new(ThemeBuildIssue.IssueType.FILE_NOT_FOUND, ThemeBuildIssue.Severity.WARNING, "f1")
	)
	report.add_issue(
		ThemeBuildIssue.new(ThemeBuildIssue.IssueType.FILE_NOT_FOUND, ThemeBuildIssue.Severity.WARNING, "f2")
	)
	report.add_issue(
		ThemeBuildIssue.new(ThemeBuildIssue.IssueType.INVALID_SLICE_NAME, ThemeBuildIssue.Severity.WARNING, "s1")
	)
	var all = report.get_all_issues()
	assert_int(all[ThemeBuildIssue.IssueType.FILE_NOT_FOUND].size()).is_equal(2)
	assert_int(all[ThemeBuildIssue.IssueType.INVALID_SLICE_NAME].size()).is_equal(1)


func test_get_all_issues_returns_dictionary() -> void:
	assert_bool(report.get_all_issues() is Dictionary).is_true()
