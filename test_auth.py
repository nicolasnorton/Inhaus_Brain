import os
import json
from google.cloud import secretmanager

def get_secret(secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/inhausbrain/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

# This is a bit complex as we need a real Firebase ID token.
# Instead, let's just check if the service is alive with a simple GET to root if it exists.
print("Checking service status...")
