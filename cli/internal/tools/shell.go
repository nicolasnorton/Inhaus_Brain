package tools

import (
	"os/exec"
	"strings"
)

// ExecuteShell runs a command in the local OS
func ExecuteShell(command string) (string, error) {
	// Simple split; a real implementation would use a proper shell lexer
	parts := strings.Fields(command)
	if len(parts) == 0 {
		return "", nil
	}

	cmd := exec.Command(parts[0], parts[1:]...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return string(out), err
	}

	return string(out), nil
}
