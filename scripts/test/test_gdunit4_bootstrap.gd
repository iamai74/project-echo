## Bootstrap smoke test: verify GdUnit4 is loaded and assertions work.
extends GdUnitTestSuite


func test_gdunit4_is_running() -> void:
	assert_bool(true).is_true()


func test_assertions_work() -> void:
	assert_int(1 + 1).is_equal(2)
	assert_int("hello".length()).is_equal(5)
	assert_object(null).is_null()
	assert_bool(true).is_true()
	assert_bool(false).is_false()
