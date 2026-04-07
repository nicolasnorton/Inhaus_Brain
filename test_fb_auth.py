import os
import json
import requests

# We need a way to get a Firebase ID token. 
# Usually, we can use the FIREBASE_CONFIG or a service account.
# Since I'm Antigravity, I'll try to use the CLI credentials if available.
import google.auth
from google.auth.transport.requests import Request

def get_id_token():
    try:
        credentials, project = google.auth.default()
        credentials.refresh(Request())
        return credentials.token
    except Exception as e:
        print(f"Error getting token: {e}")
        return None

token = get_id_token()
if token:
    print(f"Token: {token[:20]}...")
    url = "https://brainweave-mcp-1096509611056.us-central1.run.app/brainweave_graph_data"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    res = requests.post(url, headers=headers, json={})
    print(f"Status: {res.status_code}")
    print(f"Body: {res.text}")
