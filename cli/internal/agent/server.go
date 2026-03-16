package agent

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/inhauscorp/inhaus-cli/internal/tools"
)

// StartServer starts the local agent daemon to listen for commands from BrainWeave
func StartServer() {
	port := os.Getenv("AGENT_PORT")
	if port == "" {
		port = "8081" // Default port for the local agent
	}

	http.HandleFunc("/execute", handleExecute)
	http.HandleFunc("/health", handleHealth)

	log.Printf("Agent mode activated. Listening for commands on :%s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	fmt.Fprintln(w, "OK")
}

func handleExecute(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Command string `json:"command"`
		Tool    string `json:"tool"`
		Path    string `json:"path"`
		Output  string `json:"output"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	var result string
	var err error

	log.Printf("Received action: %s", req.Tool)

	switch req.Tool {
	case "shell":
		result, err = tools.ExecuteShell(req.Command)
	case "fs_read":
		result, err = tools.ReadFile(req.Path)
	case "fs_list":
		var opts []string
		opts, err = tools.ListDirectory(req.Path)
		if err == nil {
			bytes, _ := json.Marshal(opts)
			result = string(bytes)
		}
	case "capture":
		if req.Output == "" {
			req.Output = "screenshot.png"
		}
		err = tools.CaptureScreen(req.Output)
		if err == nil {
			result = fmt.Sprintf("Screenshot saved to %s", req.Output)
		}
	default:
		http.Error(w, "Unknown tool", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err != nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": "error",
			"error":  err.Error(),
		})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"result": result,
	})
}
