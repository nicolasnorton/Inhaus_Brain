package tools

import (
	"image/png"
	"os"

	"github.com/kbinani/screenshot"
)

// CaptureScreen takes a screenshot of the primary display
func CaptureScreen(outputPath string) error {
	bounds := screenshot.GetDisplayBounds(0)

	img, err := screenshot.CaptureRect(bounds)
	if err != nil {
		return err
	}

	file, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer file.Close()

	if err := png.Encode(file, img); err != nil {
		return err
	}

	return nil
}
