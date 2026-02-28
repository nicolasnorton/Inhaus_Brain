import os
import json
import urllib.request
import firebase_admin
from firebase_admin import auth, credentials

# Initialize Firebase Admin with default credentials
cred = credentials.Certificate("../serviceAccountKey.json") if os.path.exists("../serviceAccountKey.json") else None
app = firebase_admin.initialize_app(cred) if cred else firebase_admin.initialize_app()

print("Generating custom token...")
uid = "test-user-terminal"
custom_token = auth.create_custom_token(uid).decode('utf-8')

print("Exchanging for ID token...")
API_KEY = os.environ.get("FIREBASE_API_KEY", "") 

data = json.dumps({
    "token": custom_token,
    "returnSecureToken": True
}).encode('utf-8')

req = urllib.request.Request(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={API_KEY}",
    data=data,
    headers={"Content-Type": "application/json"}
)

response = urllib.request.urlopen(req)
id_token = json.loads(response.read())['idToken']

print("Calling staging function...")
staging_url = "https://generate-content-401317811527.us-central1.run.app"
payload = json.dumps({
    "prompt": "hello, show me the marketing intelligence dashboard",
    "model": "gemini-2.5-flash-lite",
    "tools": ["weather", "charts", "meetings", "skill_creator", "proposal", "video_generation", "deep_research", "orchestrate_task"]
}).encode('utf-8')

proxy_req = urllib.request.Request(
    staging_url,
    data=payload,
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {id_token}"
    }
)

try:
    proxy_resp = urllib.request.urlopen(proxy_req)
    print(f"Status Code: {proxy_resp.getcode()}")
    print("Response JSON:")
    print(json.loads(proxy_resp.read()))
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}: {e.read().decode()}")

