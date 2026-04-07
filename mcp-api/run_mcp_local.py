import os
import sys
from flask import Flask, request, jsonify
from flask_cors import CORS
from unittest.mock import MagicMock

# Set up environment
os.environ["GCP_PROJECT"] = "inhausbrain"
os.environ["WALKTHROUGH_FULL_FIXES_ENABLED"] = "true"
os.environ["GOOGLE_API_KEY"] = "AIzaSyBhfmPhi3DXMz8ALx02L79fwtrhQfj1hdg"

# Import main (requires some mocking to avoid full GCP init if possible)
import main

# Mock _authed_owner to return a specific ID
main._authed_owner = lambda req: "I52W9ogEVuY5ccttEXk4H0ht46B2"
main._is_superadmin = lambda req: True

if __name__ == "__main__":
    main.app.run(port=8080)
