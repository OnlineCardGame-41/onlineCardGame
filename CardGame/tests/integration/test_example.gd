extends GutTest        # класс GutTest идёт с плагином GUT

func test_passes():
	# этот тест пройдёт, потому что 1 действительно равно 1
	assert_eq(1, 1)

func test_fails():
	# этот тест упадёт, потому что строки не совпадают
	assert_eq("hello", "goodbye")
