import json
import os
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from gemini_client import GeminiClient
import tools as custom_tools

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
        model_name = data.get("model", "gemini-1.5-flash")

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
        model_name = data.get("model", "gemini-3-flash-preview")
        prompt = data.get("prompt")
        config = data.get("config", {})
        system_instruction = data.get("systemInstruction")
        tools = data.get("tools")
        thinking = data.get("thinking", False)
        audio = data.get("audio", False)
        use_google_search = data.get("useGoogleSearch", False)
        
        # Inject custom tool definitions if requested by string
        if isinstance(tools, list):
            new_tools = []
            for t in tools:
                if t == "weather":
                    new_tools.append(custom_tools.get_weather_schema().to_json_dict())
                elif t == "charts":
                    new_tools.append(custom_tools.get_charts_schema().to_json_dict())
                elif t == "meetings":
                    new_tools.append(custom_tools.get_meetings_schema().to_json_dict())
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
        response = client.generate_content(
            model_name=model_name,
            prompt=prompt,
            generation_config=config,
            system_instruction=system_instruction,
            tools=tools,
            thinking=thinking,
            audio=audio,
            use_google_search=use_google_search
        )

        # Use the built-in serializer for clean output
        result = client._serialize_response(response)
        
        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )
        
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
        model = data.get("model", "gemini-2.0-flash-thinking-exp-01-21") 
        
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
def generate_image(req: https_fn.Request) -> https_fn.Response:
    """Generate image using Imagen via Gemini SDK."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "imagen-3.0-generate-001")
        
        client = GeminiClient()
        images = client.generate_image(model=model, prompt=prompt)
        
        # Serialize images (base64)
        image_data = []
        for img in images:
            image_data.append({
                "mimeType": img.image.mime_type,
                "data": img.image.data.hex() # Just a placeholder or hex for now
            })
            
        return https_fn.Response(
            json.dumps({"images": image_data}),
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
        model = data.get("model", "gemini-1.5-flash")
        
        client = GeminiClient()
        total_tokens = client.count_tokens(model_name=model, prompt=prompt)
        
        return https_fn.Response(
            json.dumps({"totalTokens": total_tokens}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})
