package pkg

import "math/rand/v2"

// Generate an ID between 100_000 and 999_999s. Starting at 100_000 makes it so
// we never have to pad with leading zeros.
func NewID() int {
	return rand.IntN(900_000) + 100_000
}
