import json
import os
from firebase_functions import https_fn
from firebase_admin import initialize_app, auth
import google.cloud.aiplatform as aiplatform

# Initialize Firebase Admin
initialize_app()

@https_fn.on_request()
def extract_structured(req: https_fn.Request) -> https_fn.Response:
    """
    Secure Proxy for Google LangExtract.
    Validates Firebase Auth ID Token before processing.
    """
    # 1. CORS Handling
    if req.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
            "Access-Control-Max-Age": "3600",
        }
        return https_fn.Response("", status=204, headers=headers)

    headers = {"Access-Control-Allow-Origin": "*"}

    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405, headers=headers)

    try:
        # 2. Authentication Check
        auth_header = req.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return https_fn.Response("Unauthorized", status=401, headers=headers)
        
        id_token = auth_header.split("Bearer ")[1]
        try:
            decoded_token = auth.verify_id_token(id_token)
            uid = decoded_token['uid']
            print(f"Auth Success: User {uid} is calling extract_structured")
        except Exception as e:
            return https_fn.Response(f"Unauthorized: {str(e)}", status=401, headers=headers)

        # 3. Payload Extraction
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400, headers=headers)

        document_text = data.get("document")
        schema = data.get("schema")
        examples = data.get("examples", [])
        model_name = data.get("model", "gemini-1.5-flash")

        if not document_text or not schema:
            return https_fn.Response("Missing document or schema", status=400, headers=headers)

        # TODO: Implement LangExtract logic here once library is confirmed in env
        # For now, return a placeholder to verify connectivity
        result = {
            "status": "success",
            "message": "LangExtract wrapper initialized. Logic implementation pending library verification.",
            "echo": {
                "document_length": len(document_text),
                "model": model_name
            },
            "extraction": {
                "sections": [],
                "grounding_html": "<b>Grounding View Placeholder</b>"
            }
        }

        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={**headers, "Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in extract_structured: {str(e)}")
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={**headers, "Content-Type": "application/json"}
        )
