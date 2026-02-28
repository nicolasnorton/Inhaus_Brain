package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	firebase "firebase.google.com/go/v4"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type PipelinePhase string

const (
	Record  PipelinePhase = "record"
	Reduce  PipelinePhase = "reduce"
	Reflect PipelinePhase = "reflect"
	Reweave PipelinePhase = "reweave"
	Verify  PipelinePhase = "verify"
	Rethink PipelinePhase = "rethink"
)

type PipelineRequest struct {
	SessionID string        `json:"sessionId"`
	Phase     PipelinePhase `json:"phase"`
	Input     string        `json:"input"`
	Context   []string      `json:"context"`
}

type PipelineResponse struct {
	Status  string `json:"status"`
	Output  string `json:"output"`
	Message string `json:"message"`
}

var firebaseApp *firebase.App

func init() {
	var err error
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	if projectID == "" {
		projectID = "inhausbrain" // Default to the beta/production project
	}
	config := &firebase.Config{ProjectID: projectID}
	firebaseApp, err = firebase.NewApp(context.Background(), config)
	if err != nil {
		log.Printf("Warning: error initializing firebase app: %v", err)
	}
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/v1/pipeline/execute", corsMiddleware(authMiddleware(handlePipelineExecute)))
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		fmt.Fprintln(w, "OK")
	})

	log.Printf("PicoClaw Go Engine listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

// CORS Middleware
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Max-Age", "3600")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	}
}

// Simple bearer token middleware
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Missing or invalid Authorization header", http.StatusUnauthorized)
			return
		}

		idToken := strings.TrimPrefix(authHeader, "Bearer ")

		// If running locally without credentials or a mock token is passed for testing
		if os.Getenv("ENV") == "local" || idToken == "test-token" {
			next.ServeHTTP(w, r)
			return
		}

		if firebaseApp == nil {
			http.Error(w, "Firebase not initialized", http.StatusInternalServerError)
			return
		}

		client, err := firebaseApp.Auth(context.Background())
		if err != nil {
			http.Error(w, "Error getting Auth client", http.StatusInternalServerError)
			return
		}

		// Verify Token
		_, err = client.VerifyIDToken(context.Background(), idToken)
		if err != nil {
			log.Printf("Token verification failed: %v", err)
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r)
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

	// Build the prompt based on phase
	var prompt string
	if req.Phase == Reduce {
		prompt = fmt.Sprintf("REDUCE PHASE:\nExtract clear atomic insights from the following raw input flow. Break down complex facts into distinct nodes.\n\n[INPUT]\n%s", req.Input)
	} else if req.Phase == Reflect {
		prompt = fmt.Sprintf("REFLECT PHASE:\nSynthesize these insights. Group them logically and create MOC (Map of Content) nodes that connect and elevate these facts.\n\n[INPUT]\n%s", req.Input)
	} else {
		prompt = fmt.Sprintf("PHASE: %s\nInput:\n%s", req.Phase, req.Input)
	}

	systemInstruction := "You are the BrainWeave Architect. Produce an array of structured knowledge nodes. Descriptions describe mechanism and implication. Content states definitive prose claims."

	// ── EDGE MODE CHECK ──────────────────────────────────────────────
	// If EDGE_MODE=true, skip cloud entirely and go straight to Gemma.
	edgeMode := os.Getenv("EDGE_MODE") == "true"
	if edgeMode {
		log.Printf("[CognitiveEngine] EDGE_MODE=true — using Gemma on-device directly")
		output, err := callGemmaFallback(prompt, systemInstruction)
		if err != nil {
			log.Printf("[CognitiveEngine] Edge fallback also failed: %v", err)
			http.Error(w, fmt.Sprintf("edge fallback failed: %v", err), http.StatusInternalServerError)
			return
		}
		respondJSON(w, output, "Edge (Gemma) generation successful")
		return
	}

	// ── CLOUD PATH: Gemini 3.1 Pro (Primary) ─────────────────────────
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		log.Printf("[CognitiveEngine] GEMINI_API_KEY not set — falling back to Gemma edge")
		output, err := callGemmaFallback(prompt, systemInstruction)
		if err != nil {
			http.Error(w, "GEMINI_API_KEY not configured and edge fallback failed", http.StatusInternalServerError)
			return
		}
		respondJSON(w, output, "Edge (Gemma) fallback — no API key")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 180*time.Second)
	defer cancel()

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		log.Printf("[CognitiveEngine] Failed to create genai client: %v — trying edge fallback", err)
		output, edgeErr := callGemmaFallback(prompt, systemInstruction)
		if edgeErr != nil {
			http.Error(w, fmt.Sprintf("cloud client failed: %v, edge also failed: %v", err, edgeErr), http.StatusInternalServerError)
			return
		}
		respondJSON(w, output, "Edge (Gemma) fallback — client init failed")
		return
	}
	defer client.Close()

	// Try primary model: gemini-3.1-pro-preview
	cloudModels := []string{"gemini-3.1-pro-preview", "gemini-2.5-pro"}
	var cloudOutput string
	var cloudSuccess bool

	for _, modelName := range cloudModels {
		log.Printf("[CognitiveEngine] Trying cloud model: %s", modelName)
		model := client.GenerativeModel(modelName)
		model.SetTemperature(0.3)
		model.ResponseMIMEType = "application/json"
		model.ResponseSchema = &genai.Schema{
			Type: genai.TypeArray,
			Items: &genai.Schema{
				Type: genai.TypeObject,
				Properties: map[string]*genai.Schema{
					"title":       {Type: genai.TypeString},
					"description": {Type: genai.TypeString},
					"content":     {Type: genai.TypeString},
					"topics":      {Type: genai.TypeArray, Items: &genai.Schema{Type: genai.TypeString}},
				},
				Required: []string{"title", "description", "content", "topics"},
			},
		}
		model.SystemInstruction = genai.NewUserContent(genai.Text(systemInstruction))

		resp, genErr := model.GenerateContent(ctx, genai.Text(prompt))
		if genErr != nil {
			log.Printf("[CognitiveEngine] %s failed: %v", modelName, genErr)
			continue
		}

		if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
			log.Printf("[CognitiveEngine] %s returned no candidates", modelName)
			continue
		}

		var outputBuilder strings.Builder
		for _, part := range resp.Candidates[0].Content.Parts {
			if text, ok := part.(genai.Text); ok {
				outputBuilder.WriteString(string(text))
			}
		}
		cloudOutput = outputBuilder.String()
		cloudSuccess = true
		log.Printf("[CognitiveEngine] ✅ Success with cloud model %s", modelName)
		break
	}

	if cloudSuccess {
		respondJSON(w, cloudOutput, "Cloud generation successful")
		return
	}

	// ── EDGE FALLBACK: Gemma via Ollama ──────────────────────────────
	log.Printf("[CognitiveEngine] All cloud models failed — invoking Gemma edge fallback")
	output, edgeErr := callGemmaFallback(prompt, systemInstruction)
	if edgeErr != nil {
		http.Error(w, fmt.Sprintf("all cloud models and edge fallback failed: %v", edgeErr), http.StatusInternalServerError)
		return
	}
	respondJSON(w, output, "Edge (Gemma) fallback — cloud unavailable")
}

// respondJSON writes a PipelineResponse as JSON to the HTTP response.
func respondJSON(w http.ResponseWriter, output string, message string) {
	response := PipelineResponse{
		Status:  "success",
		Output:  output,
		Message: message,
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// callGemmaFallback runs the prompt through a local Ollama instance.
// Environment variables:
//   - EDGE_FALLBACK_MODEL: model name (default "gemma3:9b")
//   - OLLAMA_HOST: Ollama endpoint (default "http://localhost:11434")
func callGemmaFallback(prompt string, systemInstruction string) (string, error) {
	ollamaHost := os.Getenv("OLLAMA_HOST")
	if ollamaHost == "" {
		ollamaHost = "http://localhost:11434"
	}
	edgeModel := os.Getenv("EDGE_FALLBACK_MODEL")
	if edgeModel == "" {
		edgeModel = "gemma3:9b"
	}

	log.Printf("[CognitiveEngine] 🧠 Gemma Edge Fallback: model=%s host=%s", edgeModel, ollamaHost)

	// Wrap prompt with JSON instruction since Gemma doesn't support responseSchema
	wrappedPrompt := fmt.Sprintf(`%s

IMPORTANT: You MUST respond with ONLY a JSON array. Each element must have these exact keys: "title" (string), "description" (string), "content" (string), "topics" (array of strings).

%s`, systemInstruction, prompt)

	ollamaReq := map[string]interface{}{
		"model":  edgeModel,
		"prompt": wrappedPrompt,
		"stream": false,
		"format": "json",
		"options": map[string]interface{}{
			"temperature": 0.3,
			"num_predict": 4096,
		},
	}

	body, err := json.Marshal(ollamaReq)
	if err != nil {
		return "", fmt.Errorf("marshal ollama request: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()

	httpReq, err := http.NewRequestWithContext(ctx, "POST", ollamaHost+"/api/generate", bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("create ollama request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("ollama request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		respBody, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("ollama returned %d: %s", resp.StatusCode, string(respBody))
	}

	var ollamaResp struct {
		Response string `json:"response"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&ollamaResp); err != nil {
		return "", fmt.Errorf("decode ollama response: %w", err)
	}

	// Clean up: Gemma sometimes wraps JSON in markdown fences
	output := strings.TrimSpace(ollamaResp.Response)
	output = strings.TrimPrefix(output, "```json")
	output = strings.TrimPrefix(output, "```")
	output = strings.TrimSuffix(output, "```")
	output = strings.TrimSpace(output)

	// Validate it's parseable JSON
	var check interface{}
	if err := json.Unmarshal([]byte(output), &check); err != nil {
		log.Printf("[CognitiveEngine] ⚠️ Gemma output is not valid JSON, wrapping: %v", err)
		// Wrap the raw text as a single-node array
		fallbackNode := []map[string]interface{}{
			{
				"title":       "Edge Processing Result",
				"description": "Generated by Gemma on-device model (unstructured fallback)",
				"content":     output,
				"topics":      []string{"edge-fallback", "gemma"},
			},
		}
		wrapped, _ := json.Marshal(fallbackNode)
		output = string(wrapped)
	}

	log.Printf("[CognitiveEngine] ✅ Gemma edge fallback successful (%d bytes)", len(output))
	return output, nil
}
