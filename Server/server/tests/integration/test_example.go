// example_test.go — положите рядом с кодом, который вы тестируете.
package example

import "testing"

func TestPasses(t *testing.T) {
	// Тест пройдёт, потому что 1 == 1.
	if 1 != 2 {
		t.Fatalf("ожидали 1 == 1")
	}
}

func TestFails(t *testing.T) {
	// Тест упадёт, потому что строки разные.
	if "hello" != "goodbye" {
		t.Fatalf(`ожидали "hello" == "goodbye" (тест демонстрационно провален)`)
	}
}
