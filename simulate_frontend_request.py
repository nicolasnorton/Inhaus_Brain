import requests
import json
import os

# Firebase Web API Key for inhausbrain project
API_KEY = os.environ.get("FIREBASE_WEB_API_KEY", "")

def get_id_token(email, password):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    response = requests.post(url, json=payload)
    if response.status_code == 200:
        return response.json()["idToken"]
    else:
        raise Exception(f"Auth failed: {response.text}")

def test_deep_research(id_token):
    # url = "http://127.0.0.1:5001/inhausbrain/us-central1/start_research"
    url = "https://start-research-btdf7nijqa-uc.a.run.app"
    
    headers = {
        "Authorization": f"Bearer {id_token}",
        "Content-Type": "application/json",
        "Origin": "https://inhausbrain-beta.web.app",
        "Referer": "https://inhausbrain-beta.web.app/"
    }
    
    payload = {
        "model": "deep-research-pro-preview-12-2025",
        "prompt": "Write a 3 sentence deep research report about the history of the Apple Macintosh.",
        "useGoogleSearch": True,
        "config": {
            "temperature": 0.7
        },
        "tools": []
    }
    
    print(f"Sending request to {url}...")
    response = requests.post(url, headers=headers, json=payload)
    
    print(f"Status Code: {response.status_code}")
    try:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except:
        print(f"Raw Response: {response.text}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-key", required=True)
    args = parser.parse_args()
    
    API_KEY = args.api_key
    
    try:
        # User's provided login from browser subagent instructions
        email = "nnorton@inhausbrain.com"
        password = "Cafeina88$"
        print("Authenticating...")
        token = get_id_token(email, password)
        print("Auth successful. Executing Deep Research payload...")
        test_deep_research(token)
    except Exception as e:
        print(f"Error: {e}")
