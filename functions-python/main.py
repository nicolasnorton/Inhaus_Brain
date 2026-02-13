import json
import os
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from gemini_client import GeminiClient
import tools as custom_tools
from dialogue_manager import DialogueManager

# Initialize global managers (note: these might reset on cold starts, strict statelessness preferred usually)
# but for simple caching, we can keep them.
# However, DialogueManager is designed to be instantiated per request or handle statelessness.


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

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def extract_structured(req: https_fn.Request) -> https_fn.Response:
    """
    Secure Proxy for Google LangExtract.
    Validates Firebase Auth ID Token before processing.
    """
    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400)

        document_text = data.get("document")
        schema = data.get("schema")
        examples = data.get("examples", [])
        model_name = data.get("model", "gemini-2.5-flash")

        if not document_text or not schema:
            return https_fn.Response("Missing document or schema", status=400)

        # 4. LangExtract logic
        import langextract
        
        # Ensure API key is set
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
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in extract_structured: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def generate_content(req: https_fn.Request) -> https_fn.Response:
    """
    Generate content using Gemini (Python SDK).
    """
    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400)

        # Extract parameters
        model_name = data.get("model", "gemini-2.5-flash")
        prompt = data.get("prompt")
        config = data.get("config", {})
        system_instruction = data.get("systemInstruction")
        tools = data.get("tools")
        thinking = data.get("thinking", False)
        audio = data.get("audio", False)
        use_google_search = data.get("useGoogleSearch", False)
        cached_content_name = data.get("cachedContentName") # Optional: Use a pre-cached context

        
        # Inject custom tool definitions if requested by string
        if isinstance(tools, list):
            new_tools = []
            for t in tools:
                if t == "weather":
                    new_tools.append(custom_tools.get_weather_schema())
                elif t == "charts":
                    new_tools.append(custom_tools.get_charts_schema())
                elif t == "meetings":
                    new_tools.append(custom_tools.get_meetings_schema())
                else:
                    new_tools.append(t)
            tools = new_tools

        # Initialize Client
        client = GeminiClient()
        
        # Diagnostic: List models if it's the first call or for debugging
        if os.environ.get("DEBUG_MODELS") == "true":
            available = client.list_models()
            print(f"Gemini Proxy: Available Models: {available}")

        print(f"Gemini Proxy: Calling {model_name} with thinking={thinking}, search={use_google_search}")
        
        # Call Generation
        print(f"Gemini Proxy: Attempting to call generation on {model_name}...")
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
            cached_content_name=cached_content_name
        )

        # Use the built-in serializer for clean output
        result = client._serialize_response(response)
        
        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in generate_content: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

def _serialize_grounding(metadata):
    """Helper to serialize grounding metadata."""
    if not metadata: return None
    return {
        "searchEntryPoint": metadata.search_entry_point.rendered_content if hasattr(metadata, 'search_entry_point') and metadata.search_entry_point else None,
        "groundingChunks": [
            {"web": {"title": chunk.web.title, "uri": chunk.web.uri}} 
            for chunk in (metadata.grounding_chunks or []) if hasattr(chunk, 'web') and chunk.web
        ]
    }

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def start_research(req: https_fn.Request) -> https_fn.Response:
    """Start a Deep Research interaction."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "gemini-2.0-flash-thinking-exp") 
        
        client = GeminiClient()
        interaction = client.create_interaction(model=model, prompt=prompt)
        
        return https_fn.Response(
            json.dumps({"interactionId": interaction.id, "status": interaction.state}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def poll_research(req: https_fn.Request) -> https_fn.Response:
    """Poll a Deep Research interaction."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        interaction_id = data.get("interactionId")
        if not interaction_id: return https_fn.Response("Missing interactionId", status=400)
        
        client = GeminiClient()
        interaction = client.get_interaction(interaction_id)
        
        return https_fn.Response(
            json.dumps({
                "interactionId": interaction.id,
                "status": interaction.state,
                "output": interaction.output,
            }),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def poll_operation(req: https_fn.Request) -> https_fn.Response:
    """Poll a standard LRO (e.g. Veo)."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        name = data.get("operationName")
        if not name: return https_fn.Response("Missing operationName", status=400)
        
        client = GeminiClient()
        op = client.get_operation(name)
        
        result = client._serialize_response(op)
        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def generate_image(req: https_fn.Request) -> https_fn.Response:
    """Generate image using Imagen via Gemini SDK."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "imagen-3.0-fast-generate-001")
        
        client = GeminiClient()
        images = client.generate_image(model=model, prompt=prompt)
        
        return https_fn.Response(
            json.dumps(client._serialize_images(images)),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def count_tokens(req: https_fn.Request) -> https_fn.Response:
    """Count tokens using Gemini SDK."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "gemini-2.5-flash")
        
        client = GeminiClient()
        total_tokens = client.count_tokens(model_name=model, prompt=prompt)
        
        return https_fn.Response(
            json.dumps({"totalTokens": total_tokens}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def create_cache(req: https_fn.Request) -> https_fn.Response:
    """Create a Context Cache."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        model = data.get("model", "gemini-2.5-flash")
        contents = data.get("contents", []) # Expects serialized Part/Content list
        ttl = data.get("ttl", 3600)
        
        # Deserialize contents if needed (simplified here, assumes client sends valid JSON for parts)
        # Real impl might need Part reconstruction like generate_content
        
        client = GeminiClient()
        cache = client.create_cached_content(model=model, contents=contents, ttl_seconds=ttl)
        
        return https_fn.Response(
            json.dumps({
                "name": cache.name,
                "expireTime": cache.expire_time.isoformat() if cache.expire_time else None
            }),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def get_live_token(req: https_fn.Request) -> https_fn.Response:
    """
    Generate a short-lived access token for Gemini Multimodal Live API (Vertex AI).
    Validates Firebase Auth ID Token before processing.
    """
    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401)

    try:
        import google.auth
        import google.auth.transport.requests

        # Use the default service account to generate an access token
        credentials, project_id = google.auth.default(
            scopes=['https://www.googleapis.com/auth/cloud-platform']
        )
        auth_req = google.auth.transport.requests.Request()
        credentials.refresh(auth_req)

        # Return the token and necessary metadata for the client.
        result = {
            "token": credentials.token,
            "projectId": project_id,
            "location": os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1"),
            "expiresAt": credentials.expiry.isoformat() if credentials.expiry else None
        }

        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in get_live_token: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def dialogue_engine(req: https_fn.Request) -> https_fn.Response:
    """
    Core Dialogue Engine Endpoint.
    Handles 'init' and 'process_turn' actions.
    """
    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405)
    
    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        action = data.get("action")
        
        manager = DialogueManager()
        
        if action == "init":
            flow = data.get("flow_definition")
            personas = data.get("personas", [])
            if not flow:
                return https_fn.Response("Missing flow_definition", status=400)
            
            result = manager.initialize_session(flow, personas)
            return https_fn.Response(
                json.dumps(result),
                status=200,
                headers={"Content-Type": "application/json"}
            )
            
        elif action == "turn":
            session_state = data.get("session_state")
            user_input = data.get("user_input", "")
            flow = data.get("flow_definition") # Re-required for now due to statelessness
            personas = data.get("personas", []) # Re-required for now
            
            # Rehydrating state
            # Optimization: In future, load from Firestore using session_id
            manager.initialize_session(flow, personas)
            
            result = manager.process_turn(session_state, user_input)
            return https_fn.Response(
                json.dumps(result),
                status=200,
                headers={"Content-Type": "application/json"}
            )
            
        else:
            return https_fn.Response(f"Unknown entity action: {action}", status=400)

    except Exception as e:
        print(f"Error in dialogue_engine: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )
@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def enqueue_agent_task(req: https_fn.Request) -> https_fn.Response:
    """
    Enqueues an agent task for asynchronous processing.
    In Production, this dispatches to Cloud Tasks.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        agent_name = data.get("agentName")
        task_input = data.get("input")
        metadata = data.get("metadata", {})

        if not agent_name or not task_input:
            return https_fn.Response("Missing agentName or input", status=400)

        # 1. Log Task Entry
        print(f"TaskQueue: Received task for '{agent_name}' (UID: {uid})")

        # 2. Production: Dispatch to Cloud Tasks
        # For now, we simulate success. Real impl uses google-cloud-tasks.
        # queue_path = "projects/inhausbrain/locations/us-central1/queues/agent-tasks"
        
        # 3. Save to Firestore (Audit/Status Tracking)
        from firebase_admin import firestore
        db = firestore.client()
        task_ref = db.collection('agent_tasks').document()
        task_ref.set({
            'agentName': agent_name,
            'input': task_input,
            'metadata': metadata,
            'status': 'queued',
            'actorId': uid,
            'createdAt': firestore.SERVER_TIMESTAMP
        })

        return https_fn.Response(
            json.dumps({"taskId": task_ref.id, "status": "queued"}),
            status=202,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in enqueue_agent_task: {str(e)}")
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def gemma_generate(req: https_fn.Request) -> https_fn.Response:
    """
    Gemma model proxy endpoint.
    Routes to Gemma 3 family models via the GenAI SDK (Vertex AI Model Garden).
    Supports: gemma-3-4b-it, gemma-3-27b-it, functiongemma-270m, translategemma-4b.
    """
    if req.method != "POST":
        return https_fn.Response("Method Not Allowed", status=405)

    uid, auth_error = _verify_auth(req)
    if auth_error:
        return https_fn.Response(auth_error, status=401)

    # Environment gate (staging only for now)
    env = req.headers.get("X-Environment", "production")
    if env == "production":
        return https_fn.Response(
            json.dumps({"error": "Gemma models are staging-only"}),
            status=403,
            headers={"Content-Type": "application/json"}
        )

    try:
        data = req.get_json()
        if not data:
            return https_fn.Response("Missing JSON body", status=400)

        model = data.get("model", "gemma-3-4b-it")
        prompt = data.get("prompt")
        temperature = data.get("temperature", 0.3)
        max_tokens = data.get("max_tokens", 1024)
        system_instruction = data.get("system_instruction")
        response_mime_type = data.get("response_mime_type")

        # Validate model is a Gemma variant
        valid_models = {"gemma-3-4b-it", "gemma-3-27b-it", "functiongemma-270m", "translategemma-4b"}
        if model not in valid_models:
            return https_fn.Response(
                json.dumps({"error": f"Invalid Gemma model: {model}. Valid: {list(valid_models)}"}),
                status=400,
                headers={"Content-Type": "application/json"}
            )

        if not prompt:
            return https_fn.Response("Missing prompt", status=400)

        print(f"Gemma Proxy: Calling {model} (UID: {uid}, env: {env})")

        # Gemma models on Vertex AI Model Garden require Vertex AI credentials (ADC),
        # not the AI Studio API key. Force Vertex AI mode.
        client = GeminiClient(force_vertex_ai=True)

        config = {"temperature": temperature, "max_output_tokens": max_tokens}
        if response_mime_type:
            config["response_mime_type"] = response_mime_type

        response = client.generate_content(
            model_name=model,
            prompt=prompt,
            generation_config=config,
            system_instruction=system_instruction,
        )

        result = client._serialize_response(response)

        # Extract text for simpler client consumption
        text = ""
        if "candidates" in result and result["candidates"]:
            parts = result["candidates"][0].get("content", {}).get("parts", [])
            for part in parts:
                if isinstance(part, dict) and "text" in part:
                    text += part["text"]

        return https_fn.Response(
            json.dumps({
                "text": text,
                "model_used": model,
                "response": text,  # Alias for backward compat
                "full_response": result,
            }),
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in gemma_generate: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )
