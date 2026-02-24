package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// PipelinePhase represents the 6R phases
type PipelinePhase string

const (
	Record  PipelinePhase = "record"
	Reduce  PipelinePhase = "reduce"
	Reflect PipelinePhase = "reflect"
	Reweave PipelinePhase = "reweave"
	Verify  PipelinePhase = "verify"
	Rethink PipelinePhase = "rethink"
)

// PipelineRequest defines the input for the cognitive engine
type PipelineRequest struct {
	SessionID string        `json:"sessionId"`
	Phase     PipelinePhase `json:"phase"`
	Input     string        `json:"input"`
	Context   []string      `json:"context"`
}

// PipelineResponse defines the output from the cognitive engine
type PipelineResponse struct {
	Status  string `json:"status"`
	Output  string `json:"output"`
	Message string `json:"message"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/v1/pipeline/execute", handlePipelineExecute)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "OK")
	})

	log.Printf("PicoClaw Go Engine listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handlePipelineExecute(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req PipelineRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("[CognitiveEngine] Executing phase %s for session %s", req.Phase, req.SessionID)

	// Placeholder for actual cognitive logic (calling Gemini/Vertex AI via Go SDK)
	resp := PipelineResponse{
		Status:  "success",
		Output:  fmt.Sprintf("Processed phase %s in Go engine", req.Phase),
		Message: "Simulation successful",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
