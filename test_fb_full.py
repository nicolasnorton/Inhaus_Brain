import os
import sys
import firebase_admin
from firebase_admin import credentials, auth

# Set up environment
os.environ["GOOGLE_CLOUD_PROJECT"] = "inhausbrain"

try:
    print("Initializing Firebase Admin...")
    firebase_admin.initialize_app()
    print("Getting user...")
    user = auth.get_user("I52W9ogEVuY5ccttEXk4H0ht46B2")
    print(f"User found: {user.uid}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()

