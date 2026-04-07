import os
import firebase_admin
from firebase_admin import credentials, auth

# We need to see if we can use a service account or default credentials
PROJECT_ID = "inhausbrain"

try:
    firebase_admin.initialize_app()
    # If the above fails, it will raise an exception.
    # Now try to verify a fake token or just list users? 
    # Listing users requires special permissions. 
    # Let's just try to get a user by ID.
    user = auth.get_user("I52W9ogEVuY5ccttEXk4H0ht46B2")
    print(f"User found: {user.uid}")
except Exception as e:
    print(f"Error: {e}")

