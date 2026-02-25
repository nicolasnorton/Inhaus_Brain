package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

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

	ctx := context.Background()
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "GEMINI_API_KEY not configured", http.StatusInternalServerError)
		return
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to create genai client: %v", err), http.StatusInternalServerError)
		return
	}
	defer client.Close()

	model := client.GenerativeModel("gemini-3.1-pro-preview")
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
	
	systemInstruction := "You are the BrainWeave Architect. Produce an array of structured knowledge nodes. Descriptions describe mechanism and implication. Content states definitive prose claims."
	model.SystemInstruction = genai.NewUserContent(genai.Text(systemInstruction))

	var prompt string
	if req.Phase == Reduce {
		prompt = fmt.Sprintf("REDUCE PHASE:\nExtract clear atomic insights from the following raw input flow. Break down complex facts into distinct nodes.\n\n[INPUT]\n%s", req.Input)
	} else if req.Phase == Reflect {
		prompt = fmt.Sprintf("REFLECT PHASE:\nSynthesize these insights. Group them logically and create MOC (Map of Content) nodes that connect and elevate these facts.\n\n[INPUT]\n%s", req.Input)
	} else {
		prompt = fmt.Sprintf("PHASE: %s\nInput:\n%s", req.Phase, req.Input)
	}

	resp, err := model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		log.Printf("Gemini generation failed: %v", err)
		http.Error(w, fmt.Sprintf("failed generating content: %v", err), http.StatusInternalServerError)
		return
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		http.Error(w, "no content generated", http.StatusInternalServerError)
		return
	}

	var output strings.Builder
	for _, part := range resp.Candidates[0].Content.Parts {
		if text, ok := part.(genai.Text); ok {
			output.WriteString(string(text))
		}
	}

	response := PipelineResponse{
		Status:  "success",
		Output:  output.String(),
		Message: "Generation successful",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
