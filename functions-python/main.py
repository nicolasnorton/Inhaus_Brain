import json
import os
from firebase_functions import https_fn
from firebase_admin import initialize_app, auth

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

        # 4. LangExtract logic
        import langextract
        
        # Initialize Google GenAI Client for fallback or specific needs if LangExtract doesn't manage it
        # LangExtract usually takes a model_name and handles its own client if not passed.
        # But we want to ensure it uses our API key.
        os.environ["GOOGLE_API_KEY"] = os.environ.get("GOOGLE_API_KEY", "")
        
        result = langextract.extract(
            input_text=document_text,
            schema=schema,
            examples=examples,
            model=model_name
        )

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

from gemini_client import GeminiClient

def _handle_cors(req: https_fn.Request) -> tuple[dict, https_fn.Response | None]:
    """Helper to handle CORS preflight."""
    if req.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
            "Access-Control-Max-Age": "3600",
        }
        return headers, https_fn.Response("", status=204, headers=headers)
    
    headers = {"Access-Control-Allow-Origin": "*"}
    return headers, None

def _verify_auth(req: https_fn.Request) -> tuple[str | None, str | None]:
    """Helper to verify Firebase Auth ID Token. Returns (uid, error_message)."""
    auth_header = req.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None, "Unauthorized: Missing Authorization header"
    
    id_token = auth_header.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid'], None
    except Exception as e:
        return None, f"Unauthorized: {str(e)}"

@https_fn.on_request(secrets=["GOOGLE_API_KEY"])
def generate_content(req: https_fn.Request) -> https_fn.Response:
    """
    Generate content using Gemini (Python SDK).
    Supports text, chat, and structured output.
    Secrets: GOOGLE_API_KEY
    """
    headers, cors_resp = _handle_cors(req)
    if cors_resp:
        return cors_resp

    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405, headers=headers)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401, headers=headers)

    try:
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400, headers=headers)

        # Extract parameters
        model_name = data.get("model", "gemini-1.5-flash")
        prompt = data.get("prompt")
        config = data.get("config", {})
        system_instruction = data.get("systemInstruction")
        
        # Initialize Client
        # Note: In Cloud Functions, secrets are available as env vars when declared in decorator
        client = GeminiClient()
        
        # Call Generation
        # TODO: Handle streaming if requested (req.args.get('stream') or data.get('stream'))
        # For now, blocking response
        
        response = client.generate_content(
            prompt=prompt,
            model_name=model_name,
            generation_config=config,
            system_instruction=system_instruction
        )
        
        # Serialize response
        # We need to extract text and other parts safely
        # google-generativeai response object needs conversion to dict
        
        candidates_data = []
        if response.candidates:
            for cand in response.candidates:
                parts_data = []
                for part in cand.content.parts:
                    # Handle Text Part
                    if hasattr(part, 'text') and part.text:
                        parts_data.append({"text": part.text})
                    
                    # Handle Function Call Part (Native Tool Use)
                    elif hasattr(part, 'function_call') and part.function_call:
                        call = part.function_call
                        parts_data.append({
                            "functionCall": {
                                "name": call.name,
                                "args": dict(call.args) if call.args else {}
                            }
                        })
                    
                    # Handle potentially raw objects in parts
                    else:
                        parts_data.append({"raw": str(part)})
                
                candidates_data.append({
                    "content": {
                        "parts": parts_data,
                        "role": cand.content.role
                    },
                    "finishReason": cand.finish_reason.name if cand.finish_reason else None,
                })

        result = {
            "candidates": candidates_data,
            "usageMetadata": {
                "promptTokenCount": response.usage_metadata.prompt_token_count if response.usage_metadata else 0,
                "candidatesTokenCount": response.usage_metadata.candidates_token_count if response.usage_metadata else 0,
                "totalTokenCount": response.usage_metadata.total_token_count if response.usage_metadata else 0,
            } if response.usage_metadata else {}
        }
        
        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={**headers, "Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in generate_content: {str(e)}")
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={**headers, "Content-Type": "application/json"}
        )

@https_fn.on_request(secrets=["GOOGLE_API_KEY"])
def count_tokens(req: https_fn.Request) -> https_fn.Response:
    """
    Count tokens using Gemini (Python SDK).
    Secrets: GOOGLE_API_KEY
    """
    headers, cors_resp = _handle_cors(req)
    if cors_resp:
        return cors_resp

    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405, headers=headers)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401, headers=headers)

    try:
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400, headers=headers)

        model_name = data.get("model", "gemini-1.5-flash")
        prompt = data.get("prompt")
        
        if not prompt:
             return https_fn.Response("Missing 'prompt' in body", status=400, headers=headers)

        client = GeminiClient()
        total_tokens = client.count_tokens(prompt, model_name)
        
        return https_fn.Response(
            json.dumps({"totalTokens": total_tokens}),
            status=200,
            headers={**headers, "Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in count_tokens: {str(e)}")
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={**headers, "Content-Type": "application/json"}
        )
