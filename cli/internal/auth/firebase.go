package auth

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Set this to your Firebase API Key used by the extension
const firebaseAPIKey = "AIzaSyBMuHqc2OlaQdgVXUvQSsbpU9_DDwb3nNA" // from extension/background.js or env

type TokenData struct {
	IDToken      string `json:"idToken"`
	RefreshToken string `json:"refreshToken"`
	Email        string `json:"email"`
}

// LoginWithPassword authenticates with Firebase using email/password and saves the token
func LoginWithPassword(email, password string) error {
	payload := map[string]string{
		"email":             email,
		"password":          password,
		"returnSecureToken": "true",
	}

	bodyBytes, _ := json.Marshal(payload)
	url := fmt.Sprintf("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s", firebaseAPIKey)

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(bodyBytes))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		var errResp struct {
			Error struct {
				Message string `json:"message"`
			} `json:"error"`
		}
		json.Unmarshal(respBytes, &errResp)
		return fmt.Errorf("authentication failed: %s", errResp.Error.Message)
	}

	var data TokenData
	if err := json.Unmarshal(respBytes, &data); err != nil {
		return err
	}

	return saveToken(data)
}

func saveToken(data TokenData) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	configDir := filepath.Join(home, ".inhaus")
	if err := os.MkdirAll(configDir, 0700); err != nil {
		return err
	}

	configPath := filepath.Join(configDir, "cli_auth.json")
	fileBytes, _ := json.MarshalIndent(data, "", "  ")

	return os.WriteFile(configPath, fileBytes, 0600)
}

func isTokenExpired(idToken string) bool {
	parts := strings.Split(idToken, ".")
	if len(parts) != 3 {
		return true
	}

	// Base64Url decode without padding
	payloadData, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return true
	}

	var payload struct {
		Exp int64 `json:"exp"`
	}
	if err := json.Unmarshal(payloadData, &payload); err != nil {
		return true
	}

	// Consider it expired if there's less than 5 minutes remaining
	return time.Now().Unix() > (payload.Exp - 300)
}

// GetStoredToken retrieves the active Firebase ID token, refreshing it if necessary
func GetStoredToken() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	configPath := filepath.Join(home, ".inhaus", "cli_auth.json")

	fileBytes, err := os.ReadFile(configPath)
	if err != nil {
		return "", fmt.Errorf("not logged in or config missing: run 'inhaus-cli auth' first")
	}

	var data TokenData
	if err := json.Unmarshal(fileBytes, &data); err != nil {
		return "", err
	}

	if isTokenExpired(data.IDToken) {
		if data.RefreshToken == "" {
			return "", fmt.Errorf("token expired and no refresh token available: run 'inhaus-cli auth' again")
		}

		newToken, err := RefreshToken(data.RefreshToken)
		if err != nil {
			return "", fmt.Errorf("failed to refresh token: %v. Please run 'inhaus-cli auth' again", err)
		}

		// Update data and save
		data.IDToken = newToken.IDToken
		data.RefreshToken = newToken.RefreshToken
		saveToken(data)
	}

	return data.IDToken, nil
}

type RefreshResponse struct {
	IDToken      string `json:"id_token"`
	RefreshToken string `json:"refresh_token"`
}

func RefreshToken(refreshToken string) (*RefreshResponse, error) {
	reqBody := fmt.Sprintf("grant_type=refresh_token&refresh_token=%s", url.QueryEscape(refreshToken))
	reqUrl := fmt.Sprintf("https://securetoken.googleapis.com/v1/token?key=%s", firebaseAPIKey)

	resp, err := http.Post(reqUrl, "application/x-www-form-urlencoded", strings.NewReader(reqBody))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("refresh failed with status %d: %s", resp.StatusCode, string(respBytes))
	}

	var data RefreshResponse
	if err := json.Unmarshal(respBytes, &data); err != nil {
		return nil, err
	}

	return &data, nil
}
