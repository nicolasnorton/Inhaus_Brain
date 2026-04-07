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
    res = requests.post(url, headers=headers, json={})
    print(f"Status: {res.status_code}")
    print(f"Body: {res.text}")

# Test both suspect services
test_endpoint("https://brainweave-mcp-1096509611056.us-central1.run.app/brainweave_graph_data")
test_endpoint("https://brainweave-mcp-api-1096509611056.us-central1.run.app/brainweave_graph_data")
