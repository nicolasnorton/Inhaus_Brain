import json
import os
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from gemini_client import GeminiClient
import base64
from google.genai import types
import tools as custom_tools
import a2ui_schema
from dialogue_manager import DialogueManager
from workspace_context_builder import WorkspaceContextBuilder
from dynamic_router import build_router_prompt_from_firestore
from session_summarizer import maybe_summarize

# ProposalsLM Integration
from proposals_functions import tune_proforma, import_packages, proposals_chat

# BigQuery Integration
from bigquery_proxy import bigqueryProxy

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
        model_name = data.get("model", "gemini-2.0-flash")

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
        cached_content_name = data.get("cachedContentName")
        previous_interaction_id = data.get("previousInteractionId")
        thinking_level = data.get("thinkingLevel")
        thinking_summaries = data.get("thinkingSummaries")
        response_json_schema = data.get("responseJsonSchema")

        # Agentic: Session summarization for long conversations
        session_messages = data.get("sessionMessages")
        if session_messages:
            summary, trimmed_messages = maybe_summarize(session_messages)
            if summary:
                # Prepend summary to system instruction
                if system_instruction:
                    system_instruction = f"{summary}\n\n---\n\n{system_instruction}"
                else:
                    system_instruction = summary
                # Replace prompt with only recent messages context
                print(f"Session summarized: {len(session_messages)} msgs -> {len(trimmed_messages)} msgs")

        # Agentic: Optionally enrich system_instruction from workspace
        use_workspace = data.get("useWorkspace", False)
        if use_workspace and uid:
            try:
                ctx_builder = WorkspaceContextBuilder()
                workspace_prompt = ctx_builder.build_system_prompt(uid)
                if workspace_prompt:
                    system_instruction = f"{workspace_prompt}\n\n---\n\n{system_instruction}" if system_instruction else workspace_prompt
                    print(f"Workspace context injected for {uid} ({len(workspace_prompt)} chars)")
            except Exception as ws_err:
                print(f"Workspace context failed (non-fatal): {ws_err}")

        # A2UI Integration: Inject the Generative UI Catalog
        a2ui_catalog = custom_tools.get_a2ui_catalog()
        a2ui_instruction = f"""
# A2UI Generation Rendering (V0.8)
You have the ability to render dynamic web components alongside your text responses.
When a user asks for a visual widget (e.g., flight card, kanban board, checklist), you MUST follow this protocol:

1. You MUST emit a `beginRendering` JSON block immediately before generating the data for the component.
2. You MUST emit a `surfaceUpdate` JSON block containing the actual component data.
3. You MUST wrap these JSON blocks in markdown fences starting with `json ---a2ui_JSON---`.

**Available Components Catalog Definition:**
```json
{json.dumps([c.model_dump() for c in a2ui_catalog], indent=2)}
```

**Example Output Flow:**
Here is the flight status you requested:
```json ---a2ui_JSON---
{json.dumps(a2ui_schema.BeginRendering(surfaceId="generated-id-123", fallbackText="Flight Status Card").model_dump())}
```
```json ---a2ui_JSON---
{json.dumps(a2ui_schema.SurfaceUpdate(surfaceId="generated-id-123", component="flightStatus", data={{"flightNumber": "UA123", "status": "On Time", "departureTime": "2026-02-21T10:00:00Z"}}).model_dump())}
```
Let me know if you need any other cards!
        """
        system_instruction = f"{a2ui_instruction}\n\n---\n\n{system_instruction}" if system_instruction else a2ui_instruction
        
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
                elif t == "skill_creator":
                    new_tools.append(custom_tools.get_skill_creator_schema())
                elif t == "proposal":
                    new_tools.append(custom_tools.get_proposal_generator_schema())
                elif t == "video_generation":
                    new_tools.append(custom_tools.get_video_generation_schema())
                elif t == "deep_research":
                    new_tools.append(custom_tools.get_deep_research_schema())
                elif t == "orchestrate_task":
                    new_tools.append(custom_tools.get_task_orchestration_schema())
                else:
                    new_tools.append(t)
            tools = new_tools

        # Finalize config with thinking parameters if present
        if thinking_level: config["thinking_level"] = thinking_level
        if thinking_summaries: config["thinking_summaries"] = thinking_summaries

        # Initialize Client
        client = GeminiClient()
        
        # Diagnostic: List models if it's the first call or for debugging
        if os.environ.get("DEBUG_MODELS") == "true":
            available = client.list_models()
            print(f"Gemini Proxy: Available Models: {available}")

        print(f"Gemini Proxy: Calling {model_name} with thinking={thinking}, search={use_google_search}")
        
        if tools:
            tool_names = []
            for t in tools:
                if isinstance(t, dict) and "name" in t:
                    tool_names.append(t["name"])
            print(f"Gemini Proxy: Passing {len(tools)} tools to SDK: {tool_names}")
        
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
            cached_content_name=cached_content_name,
            response_json_schema=response_json_schema
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
        model = data.get("model", "deep-research-pro-preview-12-2025") 
        
        raw_tools = data.get("tools")
        processed_tools = None
        
        if raw_tools:
            processed_tools = []
            # Interactions API expects a list of Tool objects or tool dictionaries
            # We need to map frontend simplified names to SDK Tool objects
            # similar to how generate_content handles it inside GeminiClient, 
            # but create_interaction expects 'tools' argument to be ready.
            
            # Since we updated create_interaction to accept 'tools', 
            # we should let GeminiClient handle the heavy lifting if possible,
            # BUT create_interaction currently just passes 'tools' through to SDK.
            # So we must construct SDK Tool objects here OR update create_interaction again.
            
            # DECISION: It's cleaner to have the tool construction logic inside GeminiClient
            # so both generate_content and create_interaction use it.
            # However, for now, let's just do a quick pass here to ensure obvious ones work.
            
            for t in raw_tools:
                if isinstance(t, str):
                   if t == "google_search_retrieval":
                       processed_tools.append(types.Tool(google_search_retrieval=types.GoogleSearchRetrieval(
                           dynamic_retrieval_config=types.DynamicRetrievalConfig(mode=types.DynamicRetrievalConfig.Mode.DYNAMIC)
                       )))
                   elif t in ["google_search", "web_search"]:
                       processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                   elif t == "code_execution":
                       processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                elif isinstance(t, dict):
                   # Pass dicts through, assuming they are valid Tool dicts or FunctionDeclarations
                   # The SDK is quite flexible with dicts for FunctionDeclarations
                   processed_tools.append(t)

        client = GeminiClient()
        # Pass all relevant Interaction params
        interaction = client.create_interaction(
            model=model, 
            prompt=prompt,
            previous_interaction_id=data.get("previousInteractionId"),
            system_instruction=data.get("systemInstruction"),
            generation_config=data.get("config"),
            tools=processed_tools
        )
        
        resp_data = {
            "interactionId": getattr(interaction, 'id', 'unknown')
        }
        
        try:
            # Safely extract status/state, handling property access errors
            status = getattr(interaction, 'state', None)
            if not status:
                status = getattr(interaction, 'status', 'unknown')
            resp_data["status"] = status
        except Exception:
            resp_data["status"] = "unknown"

        return https_fn.Response(
            json.dumps(resp_data),
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
        
        # Use our new serializer for Interaction responses
        result = client._serialize_interaction(interaction)
        
        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

def _normalize_operation_response(op_dict: dict, operation_name: str) -> dict:
    """Normalizes a raw operation dict from the SDK into a Flutter-friendly format."""
    if not isinstance(op_dict, dict):
        return {"operationName": operation_name, "done": False, "error": f"Unexpected type: {type(op_dict)}"}
    
    done = op_dict.get("done", False)
    metadata = op_dict.get("metadata", {})
    
    result_data = None
    if done:
        # Vertex AI fetchPredictOperation returns result in "response"
        response_block = op_dict.get("response", {})
        # ML Dev might return result in "result"
        if not response_block:
            response_block = op_dict.get("result", {})
        
        # Extract video URIs from generateVideoResponse
        gen_video_resp = response_block.get("generateVideoResponse", response_block)
        generated_samples = gen_video_resp.get("generatedSamples", [])
        
        video_uris = []
        for sample in generated_samples:
            video = sample.get("video", {})
            uri = video.get("uri") if isinstance(video, dict) else None
            if uri:
                video_uris.append(uri)
        
        if video_uris:
            result_data = {"videoUri": video_uris[0], "custom_type": "veo_result", "all_videos": video_uris}
        elif response_block:
            result_data = response_block
    
    return {
        "operationName": operation_name,
        "done": done,
        "metadata": str(metadata) if metadata else "{}",
        "custom_type": "veo_lro" if "veo" in operation_name.lower() else "lro_op",
        "result": result_data
    }

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
        
        print(f"DEBUG: Poll Operation - name: {name}")
        client = GeminiClient()
        op = client.get_operation(name)
        print(f"DEBUG: Operation raw response: {json.dumps(op, default=str)[:500]}")
        
        # The SDK internal methods return raw dicts — normalize for Flutter client
        result = _normalize_operation_response(op, name)
        return https_fn.Response(
            json.dumps(result, default=str),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in poll_operation: {str(e)}")
        import traceback
        error_trace = traceback.format_exc()
        print(error_trace)
        return https_fn.Response(
            json.dumps({"error": str(e), "traceback": error_trace}), 
            status=500, 
            headers={"Content-Type": "application/json"}
        )

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
        model = data.get("model", "gemini-2.0-flash")
        
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
        model = data.get("model", "gemini-2.0-flash")
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
def generate_nano_banana(req: https_fn.Request) -> https_fn.Response:
    """
    Generate images using Nano Banana models via Gemini 2.5/3.0 Native Image Generation.
    Uses generate_content with response_modalities=['Image'] instead of legacy Imagen API.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "gemini-2.5-flash-image")
        
        # Optional config
        aspect_ratio = data.get("aspectRatio")
        image_size = data.get("imageSize") 
        response_modalities = data.get("responseModalities") # e.g. ["Image"] or ["Text", "Image"]
        reference_images = data.get("referenceImages") # List of {data: base64, mime_type: str}

        client = GeminiClient()
        response = client.generate_nano_banana(
            prompt=prompt,
            model=model,
            response_modalities=response_modalities,
            aspect_ratio=aspect_ratio,
            image_size=image_size,
            reference_images=reference_images
        )
        
        # Use existing serializer - it handles inline_data images
        return https_fn.Response(
            json.dumps(client._serialize_response(response)),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in generate_nano_banana: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def upload_file(req: https_fn.Request) -> https_fn.Response:
    """
    Upload a file using the Gemini Files API.
    Used for large documents (PDFs, Videos) for Long Context & Document Processing.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        file_data = data.get("data") # Base64 encoded string
        mime_type = data.get("mimeType")
        display_name = data.get("displayName")
        
        if not file_data or not mime_type:
            return https_fn.Response("Missing data or mimeType", status=400)
            
        file_bytes = base64.b64decode(file_data)
        
        client = GeminiClient()
        uploaded_file = client.upload_file(
            file_bytes=file_bytes,
            mime_type=mime_type,
            display_name=display_name
        )
        
        return https_fn.Response(
            json.dumps({
                "name": uploaded_file.name,
                "uri": uploaded_file.uri,
                "mimeType": uploaded_file.mime_type,
                "sizeBytes": uploaded_file.size_bytes,
                "custom_type": "uploaded_file"
            }),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in upload_file: {str(e)}")
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def process_document(req: https_fn.Request) -> https_fn.Response:
    """
    Process a document (PDF, etc.) for understanding/extraction.
    Accepts either a File URI (from upload_file) or inline base64 data.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt", "Analyze this document.")
        model = data.get("model", "gemini-2.0-flash")
        
        file_uri = data.get("fileUri")
        inline_data = data.get("inlineData") # {data: b64, mimeType: str}
        response_json_schema = data.get("responseJsonSchema")
        
        contents = []
        
        if file_uri:
            mime_type = data.get("mimeType", "application/pdf")
            contents.append(types.Part.from_uri(file_uri=file_uri, mime_type=mime_type))
        elif inline_data:
            raw_data = base64.b64decode(inline_data["data"])
            contents.append(types.Part.from_bytes(data=raw_data, mime_type=inline_data["mimeType"]))
        else:
            return https_fn.Response("Missing document data (fileUri or inlineData)", status=400)
            
        contents.append(prompt)
        
        client = GeminiClient()
        response = client.generate_content(
            model_name=model,
            prompt=contents, # Pass list directly
            response_json_schema=response_json_schema
        )
        
        return https_fn.Response(
            json.dumps(client._serialize_response(response)),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in process_document: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})
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

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def chunk_and_embed(req: https_fn.Request) -> https_fn.Response:
    """Chunks text and generates embeddings."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        text = data.get("text")
        chunk_size = data.get("chunkSize", 1000)
        chunk_overlap = data.get("chunkOverlap", 200)
        model = data.get("model", "text-embedding-004")
        
        if not text:
             return https_fn.Response("Missing text", status=400)

        # 1. Chunking logic (simple split by character for now, improved later)
        # Ideally use a tokenizer-aware splitter but for MVP this is okay
        chunks = []
        start = 0
        text_len = len(text)
        
        # Prevent infinite loop if chunk_size <= chunk_overlap
        if chunk_size <= chunk_overlap:
             chunk_size = chunk_overlap + 100

        while start < text_len:
             end = start + chunk_size
             if end > text_len:
                 end = text_len
             
             chunks.append(text[start:end])
             
             if end == text_len:
                 break
                 
             start = end - chunk_overlap
        
        # 2. Embedding logic
        client = GeminiClient()
        embeddings = client.embed_content(
             model=model,
             content=chunks,
             task_type="retrieval_document"
        )
        
        return https_fn.Response(
            json.dumps({"chunks": chunks, "embeddings": embeddings}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in chunk_and_embed: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def generate_nano_banana(req: https_fn.Request) -> https_fn.Response:
    """Generate images using Nano Banana (native Gemini image generation).
    
    Uses gemini-2.5-flash-image or gemini-3-pro-image-preview via
    generate_content with response_modalities=['Image'].
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        prompt = data.get("prompt")
        model = data.get("model", "gemini-2.5-flash-image")
        aspect_ratio = data.get("aspectRatio")
        image_size = data.get("imageSize")  # "2K" or "4K" for Pro only
        response_modalities = data.get("responseModalities")  # e.g. ["Image"] or ["Text", "Image"]
        reference_images = data.get("referenceImages")  # List of {data: base64, mime_type: str}

        if not prompt:
            return https_fn.Response("Missing prompt", status=400)

        client = GeminiClient()
        response = client.generate_nano_banana(
            prompt=prompt,
            model=model,
            response_modalities=response_modalities,
            aspect_ratio=aspect_ratio,
            image_size=image_size,
            reference_images=reference_images,
        )

        result = client._serialize_response(response)

        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in generate_nano_banana: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def upload_file(req: https_fn.Request) -> https_fn.Response:
    """Upload a file via the Gemini Files API.
    
    Returns file metadata including name and URI for use in subsequent
    generate_content calls. Best for large documents, videos, etc.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        import base64
        data = req.get_json()
        file_data_b64 = data.get("fileData")  # base64 encoded
        mime_type = data.get("mimeType")
        display_name = data.get("displayName")

        if not file_data_b64 or not mime_type:
            return https_fn.Response("Missing fileData or mimeType", status=400)

        file_bytes = base64.b64decode(file_data_b64)

        client = GeminiClient()
        uploaded = client.upload_file(
            file_bytes=file_bytes,
            mime_type=mime_type,
            display_name=display_name
        )

        result = {
            "name": uploaded.name,
            "uri": uploaded.uri,
            "mimeType": getattr(uploaded, 'mime_type', mime_type),
            "sizeBytes": getattr(uploaded, 'size_bytes', len(file_bytes)),
            "state": str(getattr(uploaded, 'state', 'ACTIVE')),
        }

        return https_fn.Response(
            json.dumps(result, default=str),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in upload_file: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def process_document(req: https_fn.Request) -> https_fn.Response:
    """Process a document (PDF, etc.) using Gemini.
    
    Supports:
    - Inline document data (base64)
    - File URI from a previous upload_file call
    - Optional structured output via responseJsonSchema
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        import base64
        data = req.get_json()
        prompt = data.get("prompt", "Summarize this document")
        model = data.get("model", "gemini-2.5-flash")
        file_uri = data.get("fileUri")  # From Files API upload
        file_mime_type = data.get("fileMimeType", "application/pdf")
        inline_data_b64 = data.get("inlineData")  # Base64 encoded document
        response_json_schema = data.get("responseJsonSchema")
        system_instruction = data.get("systemInstruction")

        if not file_uri and not inline_data_b64:
            return https_fn.Response("Missing fileUri or inlineData", status=400)

        # Build multipart prompt
        from google.genai import types
        contents = []

        if file_uri:
            # Use file from Files API
            contents.append(
                types.Part.from_uri(file_uri=file_uri, mime_type=file_mime_type)
            )
        elif inline_data_b64:
            # Inline document data
            doc_bytes = base64.b64decode(inline_data_b64)
            contents.append(
                types.Part.from_bytes(data=doc_bytes, mime_type=file_mime_type)
            )

        contents.append(prompt)

        client = GeminiClient()
        response = client.generate_content(
            model_name=model,
            prompt=contents,
            system_instruction=system_instruction,
            response_json_schema=response_json_schema,
        )

        result = client._serialize_response(response)

        return https_fn.Response(
            json.dumps(result),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in process_document: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )

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
        import os

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
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


# ═══════════════════════════════════════════════════════════════
# Phase 4: Source Verification Agent + Confidence Scoring
# ═══════════════════════════════════════════════════════════════

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def verify_output(req: https_fn.Request) -> https_fn.Response:
    """Verifies generated output against source material.
    
    Analyzes each claim in the output, checks for source support,
    flags hallucinations, and returns a confidence score.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        output_text = data.get("output", "")
        source_text = data.get("sources", "")
        output_type = data.get("outputType", "report")  # report, audio_script, mind_map
        
        if not output_text or not source_text:
            return https_fn.Response(json.dumps({"error": "Missing output or sources"}), status=400, headers={"Content-Type": "application/json"})

        client = GeminiClient()

        # Step 1: Claim Extraction + Verification (Flash for speed)
        verification_prompt = f"""You are a strict fact-checking agent. Analyze the generated output against the provided sources.

For each factual claim in the output:
1. Find the supporting passage in the sources
2. Mark as SUPPORTED, UNSUPPORTED, or PARTIALLY_SUPPORTED
3. If unsupported, flag as a potential hallucination

Output strictly as JSON:
{{
  "claims": [
    {{
      "claim": "the factual statement",
      "status": "SUPPORTED|UNSUPPORTED|PARTIALLY_SUPPORTED",
      "source_passage": "the matching source text or null",
      "source_name": "which source document",
      "confidence": 0.0-1.0
    }}
  ],
  "overall_score": 0.0-1.0,
  "citation_coverage": 0.0-1.0,
  "hallucination_count": 0,
  "suggestions": ["list of improvements"]
}}

OUTPUT TO VERIFY:
{output_text[:8000]}

SOURCES:
{source_text[:12000]}"""

        result = client.generate_content(
            prompt=verification_prompt,
            model="gemini-2.5-flash",
            generation_config={
                "response_mime_type": "application/json",
                "temperature": 0.1  # Low temp for factual analysis
            }
        )

        # Parse the verification result
        verification_text = ""
        if hasattr(result, 'text'):
            verification_text = result.text
        elif hasattr(result, 'candidates') and result.candidates:
            for part in result.candidates[0].content.parts:
                if hasattr(part, 'text'):
                    verification_text += part.text

        # Try to parse as JSON, fallback to raw
        try:
            verification_json = json.loads(verification_text)
        except json.JSONDecodeError:
            verification_json = {
                "overall_score": 0.7,
                "citation_coverage": 0.5,
                "hallucination_count": 0,
                "suggestions": ["Verification parsing failed - manual review recommended"],
                "raw_analysis": verification_text[:2000]
            }

        return https_fn.Response(
            json.dumps(verification_json),
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Error in verify_output: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


# ═══════════════════════════════════════════════════════════════
# Phase 5.2: Multi-Speaker Audio Synthesis (Cloud TTS)
# ═══════════════════════════════════════════════════════════════

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def synthesize_audio(req: https_fn.Request) -> https_fn.Response:
    """Synthesizes multi-speaker audio from a podcast script.
    
    Parses [Host 1]: and [Host 2]: labels, routes to different
    Google Cloud TTS voices, and concatenates audio segments.
    Returns base64-encoded audio.
    """
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json()
        script = data.get("script", "")
        voice_config = data.get("voiceConfig", {})
        
        if not script:
            return https_fn.Response(json.dumps({"error": "Missing script"}), status=400, headers={"Content-Type": "application/json"})

        # Voice mapping
        host1_voice = voice_config.get("host1", "en-US-Journey-D")  # Energetic male
        host2_voice = voice_config.get("host2", "en-US-Journey-F")  # Thoughtful female
        
        # Parse script into segments
        import re
        segments = []
        # Split by [Host X]: patterns
        pattern = re.compile(r'\[(Host [12])\]:\s*(.*?)(?=\[Host [12]\]:|$)', re.DOTALL)
        matches = pattern.findall(script)
        
        if not matches:
            # Fallback: treat entire script as Host 1
            segments.append({"speaker": "Host 1", "text": script, "voice": host1_voice})
        else:
            for speaker, text in matches:
                text = text.strip()
                if text:
                    voice = host1_voice if speaker == "Host 1" else host2_voice
                    segments.append({"speaker": speaker, "text": text, "voice": voice})

        # Attempt Cloud TTS synthesis
        try:
            from google.cloud import texttospeech_v1 as tts
            
            tts_client = tts.TextToSpeechClient()
            audio_segments = []
            
            for seg in segments:
                # Build SSML for natural pacing
                ssml = f'<speak><prosody rate="medium" pitch="0st">{seg["text"]}</prosody></speak>'
                
                synthesis_input = tts.SynthesisInput(ssml=ssml)
                voice_params = tts.VoiceSelectionParams(
                    language_code="en-US",
                    name=seg["voice"]
                )
                audio_config = tts.AudioConfig(
                    audio_encoding=tts.AudioEncoding.MP3,
                    speaking_rate=1.0,
                    pitch=0.0
                )
                
                response = tts_client.synthesize_speech(
                    input=synthesis_input,
                    voice=voice_params,
                    audio_config=audio_config
                )
                
                audio_segments.append({
                    "speaker": seg["speaker"],
                    "audio": base64.b64encode(response.audio_content).decode("utf-8"),
                    "duration_estimate": len(seg["text"]) / 15  # ~15 chars/sec estimate
                })
            
            return https_fn.Response(
                json.dumps({
                    "segments": audio_segments,
                    "format": "mp3",
                    "totalSegments": len(audio_segments),
                    "synthesizer": "cloud_tts"
                }),
                status=200,
                headers={"Content-Type": "application/json"}
            )
            
        except ImportError:
            # Cloud TTS not available, return segment metadata for client-side handling
            print("Cloud TTS not available, returning segment metadata only")
            return https_fn.Response(
                json.dumps({
                    "segments": [{"speaker": s["speaker"], "text": s["text"], "voice": s["voice"]} for s in segments],
                    "format": "metadata_only",
                    "totalSegments": len(segments),
                    "synthesizer": "none",
                    "message": "Cloud TTS not available. Install google-cloud-texttospeech for audio synthesis."
                }),
                status=200,
                headers={"Content-Type": "application/json"}
            )

    except Exception as e:
        print(f"Error in synthesize_audio: {str(e)}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


# ═══════════════════════════════════════════════════════════════
# Agentic Architecture: Workspace, Memory, Skills, Heartbeat
# ═══════════════════════════════════════════════════════════════

@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def build_system_prompt(req: https_fn.Request) -> https_fn.Response:
    """Build system prompt from Firestore workspace documents."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json() or {}
        include_memory = data.get("includeMemory", True)

        ctx_builder = WorkspaceContextBuilder()
        prompt = ctx_builder.build_system_prompt(uid, include_memory=include_memory)

        return https_fn.Response(
            json.dumps({"systemPrompt": prompt, "charCount": len(prompt)}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Error in build_system_prompt: {str(e)}")
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def update_memory(req: https_fn.Request) -> https_fn.Response:
    """Update the user's long-term memory document."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        from firebase_admin import firestore as fs
        db = fs.client()
        data = req.get_json()

        section = data.get("section", "General")
        content = data.get("content", "")
        mode = data.get("mode", "append")

        ref = db.collection('workspaces').document(uid).collection('docs').document('memory')
        snap = ref.get()
        current = snap.to_dict().get('content', '') if snap.exists and snap.to_dict() else "# Brian's Memory\n"

        from datetime import datetime
        timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M')

        if mode == "replace":
            import re
            pattern = re.compile(r'## ' + re.escape(section) + r'[^\n]*\n[\s\S]*?(?=\n## |\Z)')
            if pattern.search(current):
                updated = pattern.sub(f'## {section}\n{content}', current)
            else:
                updated = f"{current}\n\n## {section}\n{content}"
        else:
            updated = f"{current}\n\n## {section} ({timestamp})\n{content}"

        ref.set({'content': updated, 'updatedAt': fs.SERVER_TIMESTAMP}, merge=True)

        return https_fn.Response(
            json.dumps({"status": "ok", "mode": mode, "section": section}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def log_activity(req: https_fn.Request) -> https_fn.Response:
    """Append to today's daily note."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        from firebase_admin import firestore as fs
        from datetime import datetime
        db = fs.client()
        data = req.get_json()

        entry = data.get("entry", "")
        if not entry:
            return https_fn.Response("Missing entry", status=400)

        today = datetime.utcnow().strftime('%Y%m%d')
        timestamp = datetime.utcnow().strftime('%H:%M')
        formatted = f"- {timestamp} {entry}"

        ref = db.collection('workspaces').document(uid).collection('daily_notes').document(today)
        snap = ref.get()

        if snap.exists and snap.to_dict():
            current = snap.to_dict().get('content', '')
            entries = list(snap.to_dict().get('entries', []))
            entries.append(formatted)
            ref.update({
                'content': f"{current}\n{formatted}",
                'entries': entries,
                'updatedAt': fs.SERVER_TIMESTAMP,
            })
        else:
            date_str = datetime.utcnow().strftime('%B %d, %Y')
            ref.set({
                'content': f"# {date_str}\n\n{formatted}",
                'entries': [formatted],
                'updatedAt': fs.SERVER_TIMESTAMP,
            })

        return https_fn.Response(
            json.dumps({"status": "ok", "date": today}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def read_memory(req: https_fn.Request) -> https_fn.Response:
    """Read memory + recent daily notes for system prompt building."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        data = req.get_json() or {}
        days = data.get("days", 3)

        ctx_builder = WorkspaceContextBuilder()
        memory = ctx_builder._get_doc_content(uid, 'memory')
        daily_notes = ctx_builder._get_recent_daily_notes(uid, days=days)

        return https_fn.Response(
            json.dumps({"memory": memory, "dailyNotes": daily_notes}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def read_skill(req: https_fn.Request) -> https_fn.Response:
    """Load full skill content by name (lazy loading)."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        from firebase_admin import firestore as fs
        db = fs.client()
        data = req.get_json()

        skill_name = data.get("skillName")
        if not skill_name:
            return https_fn.Response("Missing skillName", status=400)

        ref = db.collection('workspaces').document(uid).collection('skills').document(skill_name)
        snap = ref.get()

        if not snap.exists:
            return https_fn.Response(
                json.dumps({"error": f"Skill '{skill_name}' not found"}),
                status=404, headers={"Content-Type": "application/json"}
            )

        skill_data = snap.to_dict()
        return https_fn.Response(
            json.dumps({
                "name": skill_data.get('name', skill_name),
                "description": skill_data.get('description', ''),
                "content": skill_data.get('content', ''),
                "references": skill_data.get('references', {}),
            }),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def create_skill(req: https_fn.Request) -> https_fn.Response:
    """Create a new skill from agent conversation."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        from firebase_admin import firestore as fs
        db = fs.client()
        data = req.get_json()

        name = data.get("name")
        description = data.get("description", "")
        content = data.get("content", "")
        references = data.get("references", {})

        if not name:
            return https_fn.Response("Missing skill name", status=400)

        ref = db.collection('workspaces').document(uid).collection('skills').document(name)
        ref.set({
            'name': name,
            'description': description,
            'content': content,
            'references': references,
            'createdAt': fs.SERVER_TIMESTAMP,
            'updatedAt': fs.SERVER_TIMESTAMP,
        })

        return https_fn.Response(
            json.dumps({"status": "created", "skillName": name}),
            status=201,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def run_heartbeat_endpoint(req: https_fn.Request) -> https_fn.Response:
    """Manually trigger heartbeat for a user (also callable by Cloud Scheduler)."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        from heartbeat_runner import run_heartbeat
        result = run_heartbeat(uid)

        return https_fn.Response(
            json.dumps(result, default=str),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


@https_fn.on_request(secrets=["GOOGLE_API_KEY"], invoker="public", cors=options.CorsOptions(cors_origins="*", cors_methods=["POST"]))
def build_dynamic_router(req: https_fn.Request) -> https_fn.Response:
    """Build router prompt dynamically from agent registry."""
    if req.method != "POST": return https_fn.Response("Method Not Allowed", status=405)
    uid, auth_error = _verify_auth(req)
    if auth_error: return https_fn.Response(auth_error, status=401)

    try:
        prompt = build_router_prompt_from_firestore(uid)
        return https_fn.Response(
            json.dumps({"routerPrompt": prompt, "charCount": len(prompt)}),
            status=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})
