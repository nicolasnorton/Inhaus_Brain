import requests
import google.auth
from google.auth.transport.requests import Request

def get_token():
    creds, project = google.auth.default()
    creds.refresh(Request())
    return creds.token

def test_endpoint(url):
    token = get_token()
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    print(f"Testing {url}...")
    try:
        res = requests.post(url, headers=headers, json={}, timeout=10)
        print(f"Status: {res.status_code}")
        print(f"Body: {res.text}")
    except Exception as e:
        print(f"Error: {e}")

test_endpoint("https://brainweave-mcp-api-1096509611056.us-central1.run.app/brainweave_graph_data")
