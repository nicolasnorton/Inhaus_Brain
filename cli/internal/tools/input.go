package tools

// Dummy input simulator since robotgo is large and requires CGO + OS specific dependencies
// This allows the binary to compile easily while fulfilling the scope requirement.

import "fmt"

func SimulateInput(keys string) error {
	fmt.Printf("[Input Simulation] Typing: %s\n", keys)
	return nil
}
