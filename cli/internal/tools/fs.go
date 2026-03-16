package tools

import (
	"os"
)

// ReadFile returns the contents of a text file
func ReadFile(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// ListDirectory returns the files and folders in a given path
func ListDirectory(path string) ([]string, error) {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var results []string
	for _, e := range entries {
		sign := " "
		if e.IsDir() {
			sign = "/"
		}
		results = append(results, e.Name()+sign)
	}
	return results, nil
}
