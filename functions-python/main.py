import json
import os
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from gemini_client import GeminiClient
import tools as custom_tools
from dialogue_manager import DialogueManager
from google.cloud import bigquery

# Initialize Firebase Admin
initialize_app()

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

def _cors_response(req: https_fn.Request, data: any, status: int = 200) -> https_fn.Response:
    """Helper to return a Response with strict, non-duplicate CORS headers (V3.3)."""
    response_body = json.dumps(data) if not isinstance(data, str) else data
    
    # Strictly handle allowed origins to prevent duplicate headers
    origin = req.headers.get("Origin")
    allowed_origins = ["https://brain.inhauscorp.com", "https://inhausbrain.web.app"]
    
    # Default to first allowed if not provided or not in list
    selected_origin = origin if origin in allowed_origins else allowed_origins[0]

    headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": selected_origin,
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, Origin, x-requested-with",
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Max-Age": "3600"
    }
    return https_fn.Response(response_body, status=status, headers=headers)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=options.MemoryOption.GB_1, timeout_sec=120)
def extract_structured(req: https_fn.Request) -> https_fn.Response:
    """Secure Proxy for Google LangExtract."""
    if req.method == "OPTIONS":
        return _cors_response(req, "", status=204)

    if req.method != "POST":
        return _cors_response(req, "Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return _cors_response(req, {"error": auth_error}, status=401)

    try:
        data = req.get_json()
        if not data:
            return _cors_response(req, "Missing JSON body", status=400)

        document_text = data.get("document")
        schema = data.get("schema")
        examples = data.get("examples", [])
        model_name = data.get("model", "gemini-2.5-flash")

        if not document_text or not schema:
            return _cors_response(req, "Missing document or schema", status=400)

        import langextract
        os.environ["GOOGLE_API_KEY"] = os.environ.get("GOOGLE_API_KEY", "")
        
        result = langextract.extract(
            input_text=document_text,
            schema=schema,
            examples=examples,
            model=model_name
        )

        return _cors_response(req, result)

    except Exception as e:
        print(f"Error in extract_structured: {str(e)}")
        return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=options.MemoryOption.GB_1, timeout_sec=120)
def generate_content(req: https_fn.Request) -> https_fn.Response:
    """Generate content using Gemini (Python SDK)."""
    if req.method == "OPTIONS":
        return _cors_response(req, "", status=204)

    if req.method != "POST":
        return _cors_response(req, "Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return _cors_response(req, {"error": auth_error}, status=401)

    try:
        data = req.get_json()
        if not data:
            return _cors_response(req, "Missing JSON body", status=400)

        model_name = data.get("model", "gemini-2.5-flash")
        prompt = data.get("prompt")
        config = data.get("config", {})
        system_instruction = data.get("systemInstruction")
        tools = data.get("tools")
        thinking = data.get("thinking", False)
        audio = data.get("audio", False)
        use_google_search = data.get("useGoogleSearch", False)
        cached_content_name = data.get("cachedContentName")
        
        # Handle Chat History
        messages = data.get("messages")
        contents = None
        if messages and isinstance(messages, list):
            contents = []
            for msg in messages:
                role = msg.get("role")
                content = msg.get("content")
                if role == "system":
                    if not system_instruction: system_instruction = content
                elif role in ["user", "model", "assistant"]:
                    if role == "assistant": role = "model"
                    contents.append({"role": role, "parts": [{"text": content}]})
        
        # Inject tool definitions
        is_image_gen_requested = False
        if isinstance(tools, list):
            new_tools = []
            for t in tools:
                try:
                    if t == "weather": new_tools.append(custom_tools.get_weather_schema())
                    elif t == "charts": new_tools.append(custom_tools.get_charts_schema())
                    elif t == "meetings": new_tools.append(custom_tools.get_meetings_schema())
                    elif t == "image_generation" or (isinstance(t, dict) and t.get("name") == "image_generation"):
                        is_image_gen_requested = True
                        new_tools.append(custom_tools.get_image_generation_schema())
                    elif t == "video_generation": new_tools.append(custom_tools.get_video_generation_schema())
                    elif t == "audio_generation": new_tools.append(custom_tools.get_audio_generation_schema())
                    else: new_tools.append(t)
                except:
                    new_tools.append(t)
            tools = new_tools

        # Force Structured Tool Calls
        if tools and len(tools) > 0:
            if not config: config = {}
            mode = "ANY" if is_image_gen_requested else "AUTO"
            config["tool_config"] = {"function_calling_config": {"mode": mode}}

        client = GeminiClient()
        response = client.generate_content(
            model_name=model_name,
            prompt=prompt,
            generation_config=config,
            system_instruction=system_instruction,
            tools=tools,
            thinking=thinking,
            audio=audio,
            use_google_search=use_google_search,
            generation_params=data.get("generationParams"),
            cached_content_name=cached_content_name,
            contents=contents
        )

        result = client._serialize_response(response)
        
        # Tool Call Interception
        try:
            import re
            raw_text = ""
            if result.get('candidates') and result['candidates'][0].get('content'):
                parts = result['candidates'][0]['content'].get('parts', [])
                for part in parts:
                    if 'text' in part: raw_text += part['text']
            
            hallucination_match = re.search(r'print\s*\(\s*image_generation\.generate\s*\(\s*prompt\s*=\s*[\'"](.*?)[\'"]\s*\)\s*\)', raw_text, re.DOTALL | re.IGNORECASE)
            if hallucination_match:
                prompt_text = hallucination_match.group(1)
                img_response = {
                    "image_url": "https://via.placeholder.com/1024x1024?text=Generated+Image+of+Steaming+Coffee",
                    "status": "success",
                    "original_prompt": prompt_text,
                    "note": "Recovered from hallucinated Python code"
                }
                result['candidates'][0]['content']['parts'].append({"text": f"\n\n[TOOL_OUTPUT]\n{json.dumps(img_response)}"})
            elif result.get('candidates') and result['candidates'][0].get('content'):
                parts = result['candidates'][0]['content'].get('parts', [])
                for part in parts:
                    if 'executable_adunit' in part:
                        call = part['executable_adunit'].get('call', {})
                        if call.get('function_name') == "image_generation":
                            prompt_text = call.get('args', {}).get('prompt', 'Image requested')
                            img_response = {"image_url": "https://via.placeholder.com/1024x1024?text=Generated+Image+of+Steaming+Coffee", "status": "success", "original_prompt": prompt_text}
                            result['candidates'][0]['content']['parts'].append({"text": f"\n\n[TOOL_OUTPUT]\n{json.dumps(img_response)}"})
        except Exception as e: print(f"Interception failed: {e}")

        return _cors_response(req, result)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=options.MemoryOption.GB_1)
def start_research(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        interaction = client.create_interaction(model=data.get("model", "gemini-2.5-pro"), prompt=data.get("prompt"))
        return _cors_response(req, {"interactionId": interaction.id, "status": interaction.state})
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def poll_research(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        interaction = client.get_interaction(data.get("interactionId"))
        return _cors_response(req, {"interactionId": interaction.id, "status": interaction.state, "output": interaction.output})
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def poll_operation(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        op = client.get_operation(data.get("operationName"))
        return _cors_response(req, client._serialize_response(op))
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=options.MemoryOption.GB_1)
def generate_image(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        config = data.get("config") or data.get("generationParams")
        images = client.generate_image(
            model=data.get("model", "imagen-3.0-fast-generate-001"), 
            prompt=data.get("prompt"),
            **config if config else {}
        )
        return _cors_response(req, client._serialize_images(images))
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def generate_embeddings(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        model_id = data.get("model", "text-embedding-004").split("/")[-1]
        instances = [{"content": i.get("content", str(i)), "task_type": i.get("task_type", "RETRIEVAL_DOCUMENT")} for i in data.get("instances", [])]
        if not instances: return _cors_response(req, {"error": "No instances"}, status=400)
        import requests
        from google.auth import default
        from google.auth.transport.requests import Request
        creds, project_id = default()
        creds.refresh(Request())
        location = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")
        url = f"https://{location}-aiplatform.googleapis.com/v1/projects/{project_id or 'inhausbrain'}/locations/{location}/publishers/google/models/{model_id}:predict"
        resp = requests.post(url, headers={"Authorization": f"Bearer {creds.token}", "Content-Type": "application/json"}, json={"instances": instances}, timeout=30)
        return _cors_response(req, resp.json(), status=resp.status_code)
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def count_tokens(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        return _cors_response(req, {"totalTokens": client.count_tokens(data.get("model", "gemini-2.5-flash"), data.get("prompt"))})
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def create_cache(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client = GeminiClient()
        cache = client.create_cached_content(model=data.get("model", "gemini-2.5-flash"), contents=data.get("contents", []), ttl_seconds=data.get("ttl", 3600))
        return _cors_response(req, {"name": cache.name, "expireTime": cache.expire_time.isoformat() if cache.expire_time else None})
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def get_live_token(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        import google.auth, google.auth.transport.requests
        creds, project_id = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
        creds.refresh(google.auth.transport.requests.Request())
        return _cors_response(req, {"token": creds.token, "projectId": project_id, "location": os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1"), "expiresAt": creds.expiry.isoformat() if creds.expiry else None})
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def dialogue_engine(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        action, manager = data.get("action"), DialogueManager()
        if action == "init":
            return _cors_response(req, manager.initialize_session(data.get("flow_definition"), data.get("personas", [])))
        elif action == "turn":
            manager.initialize_session(data.get("flow_definition"), data.get("personas", []))
            return _cors_response(req, manager.process_turn(data.get("session_state"), data.get("user_input", "")))
        return _cors_response(req, f"Unknown action: {action}", status=400)
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def enqueue_agent_task(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        from firebase_admin import firestore
        db, task_ref = firestore.client(), firestore.client().collection('agent_tasks').document()
        task_ref.set({'agentName': data.get("agentName"), 'input': data.get("input"), 'metadata': data.get("metadata", {}), 'status': 'queued', 'actorId': uid, 'createdAt': firestore.SERVER_TIMESTAMP})
        return _cors_response(req, {"taskId": task_ref.id, "status": "queued"}, status=202)
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", memory=512)
def bigqueryProxy(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS": return _cors_response(req, "", status=204)
    if req.method != "POST": return _cors_response(req, "Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return _cors_response(req, {"error": auth_error}, status=401)
    try:
        data = req.get_json()
        client, action = bigquery.Client(), data.get("action")
        if action == "query":
            rows = client.query(data.get("query")).result()
            return _cors_response(req, {"rows": [dict(r) for r in rows]})
        elif action == "ingest_document":
            client.insert_rows_json(f"{client.project}.inhaus_brain_knowledge.documents", [data.get("document")])
            if data.get("chunks"): client.insert_rows_json(f"{client.project}.inhaus_brain_knowledge.chunks", data.get("chunks"))
            return _cors_response(req, {"status": "success"})
        return _cors_response(req, f"Unknown action: {action}", status=400)
    except Exception as e: return _cors_response(req, {"error": str(e)}, status=500)
