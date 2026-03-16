package mcp

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/inhauscorp/inhaus-cli/internal/auth"
)

// Uses the deployed or local MCP endpoint
var brainweaveBaseURL = getEnv("BRAINWEAVE_MCP_URL", "https://brainweave-mcp-1096509611056.us-central1.run.app")

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// QueryGraph calls the brainweave_graph_query tool
func QueryGraph(query string) (string, error) {
	payload := map[string]interface{}{
		"query": query,
		"limit": 5,
	}

	bodyBytes, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", brainweaveBaseURL+"/brainweave_graph_query", bytes.NewBuffer(bodyBytes))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")

	// Get token and attach it
	token, err := auth.GetStoredToken()
	if err == nil && token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(respBytes), nil
}

// Annotate calls the brainweave_annotate tool
func Annotate(nodeID, text string) (string, error) {
	payload := map[string]interface{}{
		"node_id": nodeID,
		"text":    text,
	}
	return postMCP("/brainweave_annotate", payload)
}

// Evolve calls the brainweave_evolve tool
func Evolve() (string, error) {
	return postMCP("/brainweave_evolve", map[string]interface{}{})
}

// LogDeviceAction logs a device action to the BrainWeave graph (BW3.0)
func LogDeviceAction(action, input, output string) {
	payload := map[string]interface{}{
		"title":        fmt.Sprintf("CLI Device Action: %s", action),
		"description":  fmt.Sprintf("CLI executed %s with input: %s", action, input),
		"content":      output,
		"node_type":    "device_action",
		"topics":       []string{"device_control", "cli", action},
		"scope":        "PRIVATE",
		"source_agent": "inhaus_cli",
	}
	// Fire-and-forget, non-fatal
	_, _ = postMCP("/brainweave_create", payload)
}

// postMCP is a generic helper for POST calls to the MCP API
func postMCP(path string, payload map[string]interface{}) (string, error) {
	bodyBytes, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", brainweaveBaseURL+path, bytes.NewBuffer(bodyBytes))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")

	token, err := auth.GetStoredToken()
	if err == nil && token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(respBytes), nil
}
