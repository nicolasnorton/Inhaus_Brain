import os
import json
import base64
from google import genai
from google.genai import types
from typing import Optional, List, Union, Dict, Any

class GeminiClient:
    """Wrapper for Google GenAI SDK (Modern v1) - Flawless Upgrade v1.5"""
    
    def __init__(self, api_key: Optional[str] = None, force_vertex_ai: bool = False):
        """
        Initialize Gemini Client.
        If force_vertex_ai is True, ignores API key and uses Vertex AI ADC.
        """
        self._api_key = api_key or os.environ.get("GOOGLE_API_KEY")
        self._force_vertex_ai = force_vertex_ai
        self._google_client = None
        self._vertex_client = None

        if not self._api_key and not force_vertex_ai:
            print("Warning: GOOGLE_API_KEY not found in environment.")

    @property
    def client(self) -> genai.Client:
        """Get the primary client (depends on initialization mode)."""
        if self._force_vertex_ai:
            return self.vertex_client
        return self.google_client

    @property
    def google_client(self) -> genai.Client:
        """Lazy-init Google AI Studio (API Key) client."""
        if not self._google_client:
            if not self._api_key:
                # Fallback to vertex if no API key
                return self.vertex_client
            print(f"GeminiClient: Initializing Google AI Client (API Key present)")
            self._google_client = genai.Client(api_key=self._api_key)
        return self._google_client

    @property
    def vertex_client(self) -> genai.Client:
        """Lazy-init Vertex AI (ADC) client."""
        if not self._vertex_client:
            project = os.environ.get("GOOGLE_CLOUD_PROJECT")
            location = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")
            print(f"GeminiClient: Initializing Vertex AI Client (Project: {project})")
            self._vertex_client = genai.Client(vertexai=True, project=project, location=location)
        return self._vertex_client

    def _normalize_model_name(self, model_name: str) -> str:
        """Normalize model names with awareness of Gemini 2.5 GA."""
        if not model_name:
            return "gemini-2.5-flash"

        name_lower = model_name.lower()

        # Explicitly preserve specialized models
        SPECIALIZED_MODELS = ["veo", "imagen", "lyra", "nano", "deep-research", "flash-image", "pro-image"]
        if any(sm in name_lower for sm in SPECIALIZED_MODELS):
            # Veo 3.1 mapping
            if "veo" in name_lower and "3.1" in name_lower:
                return "veo-3.1-generate-001"
            # Nano Banana / Native Image Generation mapping
            if "nano-banana" in name_lower or "nano_banana" in name_lower:
                if "pro" in name_lower:
                    return "gemini-3-pro-image-preview"
                return "gemini-2.5-flash-image"
            if "flash-image" in name_lower or "flash_image" in name_lower:
                return "gemini-2.5-flash-image"
            if "pro-image" in name_lower or "pro_image" in name_lower:
                return "gemini-3-pro-image-preview"
            return model_name

        # Gemini 2.5 is GA - pass through directly
        # Map Gemini 2.0/2.5 to 2.5 Baseline
        if "gemini-2.0" in name_lower or "gemini-2.5" in name_lower:
            if "lite" in name_lower:
                return "gemini-2.5-flash-lite"
            if "pro" in name_lower:
                return "gemini-2.5-pro"
            return "gemini-2.5-flash"

        # Map Gemini 3 (Frontier)
        if "gemini-3" in name_lower:
            if "pro" in name_lower:
                return "gemini-3-pro-preview"
            return "gemini-3-flash-preview"

        # Standardize simple/legacy names to latest 2.5/3.0
        if name_lower in ["gemini-flash", "gemini-pro", "flash", "pro"]:
             return "gemini-3-pro-preview" if "pro" in name_lower else "gemini-2.5-flash"
            
        return model_name

    def route_request(self, prompt: Union[str, List[Any]], model_hint: Optional[str] = None, task_complexity: str = "medium") -> str:
        """
        Intelligently route request to the best model.
        Flash for speed/simple, Pro for quality/complex.
        """
        if model_hint and model_hint != "auto":
            return self._normalize_model_name(model_hint)

        # Heuristic routing
        estimated_tokens = 0
        if isinstance(prompt, str):
            estimated_tokens = len(prompt) / 4
        elif isinstance(prompt, list):
             # Rough estimation for list logic
             estimated_tokens = sum(len(str(p)) for p in prompt) / 4

        if task_complexity == "high" or estimated_tokens > 10000:
             return "gemini-2.5-pro"
        
        return "gemini-2.5-flash"

    def generate_content(
        self, 
        prompt: Union[str, List[Union[str, Any]]], 
        model_name: str = "auto",
        generation_config: Optional[Dict[str, Any]] = None,
        stream: bool = False,
        system_instruction: Optional[str] = None,
        tools: Optional[List[Any]] = None,
        thinking: bool = False,
        audio: bool = False,
        use_google_search: bool = False,
        generation_params: Optional[Dict[str, Any]] = None,
        cached_content_name: Optional[str] = None,
        response_json_schema: Optional[Dict[str, Any]] = None
    ) -> Any:
        """
        Generate content using the specified model with intelligent routing.
        Automatically routes Veo models to generate_video.
        """
        # Intelligent Routing
        model = self.route_request(prompt, model_name)
        
        # Route Veo models to generate_video
        if "veo" in model.lower():
            return self.generate_video(prompt, model=model, config=generation_params)

        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")

        config_params = (generation_config or {}).copy()
        
        # Handle thinking mode (Jan 2026 standard)
        thinking_config = None
        if thinking:
            # Newer models support thinking_level in generation_config
            # but for GenerateContentConfig we still use thinking_config for now
            # if thinking_level is not provided in generation_config.
            if "thinking_level" not in config_params:
                config_params["thinking_level"] = "medium"
            if "thinking_summaries" not in config_params:
                config_params["thinking_summaries"] = "auto"
            
            # Legacy thinking_config part for backward compatibility with SDK's GenerateContent
            thinking_config = types.ThinkingConfig(include_thoughts=True)
            config_params.pop("thinking_config", None)

        processed_tools = []
        
        # 1. Google Search / Grounding (Jan 2026 Standard)
        # Use GoogleSearchRetrieval for broader dynamic grounding
        if use_google_search:
            # Check if dynamic_retrieval_config is passed in generation_params
            dynamic_threshold = (generation_params or {}).get("dynamic_threshold", 0.3)
            processed_tools.append(
                types.Tool(
                    google_search_retrieval=types.GoogleSearchRetrieval(
                        dynamic_retrieval_config=types.DynamicRetrievalConfig(
                            mode=types.DynamicRetrievalConfig.Mode.DYNAMIC,
                            dynamic_threshold=dynamic_threshold,
                        )
                    )
                )
            )

        # 2. Function Declarations (Tools)
        if tools and not thinking:
            function_declarations = []
            for tool in tools:
                if isinstance(tool, dict):
                    # Check for existing tool wrappers
                    if "google_search_retrieval" in tool or "googleSearchRetrieval" in tool:
                         processed_tools.append(types.Tool(google_search_retrieval=types.GoogleSearchRetrieval()))
                    elif "google_search" in tool or "googleSearch" in tool:
                         # Legacy fallback to standard search if explicitly requested
                         processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    elif "google_maps" in tool or "googleMaps" in tool:
                        processed_tools.append(types.Tool(google_maps=types.GoogleMaps()))
                    elif "code_execution" in tool or "codeExecution" in tool:
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    elif "function_declarations" in tool or "functionDeclarations" in tool:
                        decls = tool.get("function_declarations") or tool.get("functionDeclarations") or []
                        function_declarations.extend(decls)
                    elif "name" in tool:
                        # Individual function declaration (e.g. from Flutter)
                        function_declarations.append(tool)
                elif isinstance(tool, str):
                    if tool == "google_search_retrieval":
                        processed_tools.append(types.Tool(
                            google_search_retrieval=types.GoogleSearchRetrieval(
                                dynamic_retrieval_config=types.DynamicRetrievalConfig(mode=types.DynamicRetrievalConfig.Mode.DYNAMIC)
                            )
                        ))
                    elif tool in ["google_search", "web_search"]:
                        processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    elif tool == "code_execution":
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    else:
                        # Treat as name of a custom tool to be retrieved? 
                        processed_tools.append(tool)
            
            # Unified Tool object for better compatibility
            # Jan 2026 Best Practice: Separate Tool objects in the list for different capabilities
            if function_declarations:
                processed_tools.append(types.Tool(function_declarations=function_declarations))

        if audio:
            config_params["response_modalities"] = ["AUDIO"]

        # Structured Output: pass response_json_schema if provided
        if response_json_schema:
            config_params["response_mime_type"] = config_params.get("response_mime_type", "application/json")
            config_params["response_json_schema"] = response_json_schema

        config = types.GenerateContentConfig(
            system_instruction=system_instruction,
            tools=processed_tools,
            thinking_config=thinking_config,
            cached_content=cached_content_name,
            **config_params
        )

        processed_contents = prompt
        if isinstance(prompt, list):
            processed_contents = []
            for item in prompt:
                if isinstance(item, dict) and "inline_data" in item:
                    data = item["inline_data"]
                    raw_data = base64.b64decode(data["data"]) if isinstance(data["data"], str) else data["data"]
                    processed_contents.append(types.Part.from_bytes(data=raw_data, mime_type=data["mime_type"]))
                elif isinstance(item, dict) and "file_data" in item:
                    processed_contents.append(types.Part.from_uri(file_uri=item["file_data"]["file_uri"], mime_type=item["file_data"]["mime_type"]))
                else:
                    processed_contents.append(item)

        # Resilient Fallback Chain
        # Stage 1: Primary Model
        # Stage 2: Gemini 2.5 Flash (GA)
        # Stage 3: Gemini 2.0 Flash (Stable)
        # Stage 4: Gemini 1.5 Flash (Legacy)
        
        fallback_models = [model, "gemini-3-pro-preview", "gemini-2.5-flash"]
        # Remove duplicates while preserving order
        fallback_models = list(dict.fromkeys(fallback_models))
        
        last_error = None
        for attempt_model in fallback_models:
            try:
                # Determine which client to use
                # Default to Vertex AI in production environments (IAM auth)
                active_client = self.vertex_client
                
                # Fallback to Google AI Studio if no project configured (Local Development)
                if not os.environ.get("GOOGLE_CLOUD_PROJECT"):
                    active_client = self.google_client
                    
                # Force Vertex for specific model families
                if any(v in attempt_model.lower() for v in ["gemma", "veo", "imagen", "lyra"]):
                    active_client = self.vertex_client
                
                print(f"GeminiClient: Attempting generation with {attempt_model}...")
                
                if stream:
                    return active_client.models.generate_content_stream(model=attempt_model, contents=processed_contents, config=config)
                else:
                    return active_client.models.generate_content(model=attempt_model, contents=processed_contents, config=config)
            
            except Exception as e:
                last_error = e
                error_msg = str(e).lower()
                print(f"GeminiClient: Failed with {attempt_model}: {e}")
                import traceback
                print(f"GeminiClient: Full traceback for {attempt_model} failure:\n{traceback.format_exc()}")
                
                # If it's a 429 (Resource Exhausted) or 503, definitely fallback
                # If it's 404 (Not Found), also fallback
                if any(x in error_msg for x in ["404", "429", "503", "500", "not found", "limit"]):
                    print(f"GeminiClient: Triggering fallback from {attempt_model}...")
                    continue
                else:
                    # Critical error (e.g. invalid prompt), don't bother retrying
                    break
        
        raise last_error or Exception("All model fallbacks failed.")

    def generate_video(self, prompt: str, model: str = "veo-3.1-generate-001", config: Optional[Dict[str, Any]] = None) -> Any:
        """Generate a video using Veo 3.1 via Vertex AI."""
        # Force Vertex AI for Veo
        client = self.vertex_client
        
        cv = {
            "duration_seconds": 5,
            "aspect_ratio": "16:9",
        }
        if config:
            if 'durationSeconds' in config: cv['duration_seconds'] = config['durationSeconds']
            if 'aspectRatio' in config: cv['aspect_ratio'] = config['aspectRatio']
            # 'resolution' is not supported in GenerateVideosConfig, so we explicitly ignore it.
            cv.update({k: v for k, v in config.items() if k not in ['durationSeconds', 'aspectRatio', 'resolution']})

        print(f"GeminiClient: Generating video with {model} via Vertex...")
        return client.models.generate_videos(
            model=model,
            prompt=prompt,
            config=types.GenerateVideosConfig(**cv)
        )

    def create_cached_content(self, model: str, contents: List[Any], ttl_seconds: int = 3600) -> Any:
        """Create a cached content resource."""
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        
        return self.client.caches.create(
            model=self._normalize_model_name(model),
            config=types.CreateCachedContentConfig(
                contents=contents,
                ttl=f"{ttl_seconds}s"
            )
        )

    def batch_generate_content(self, model: str, requests: List[Dict[str, Any]]) -> Any:
        """
        Execute batch generation requests.
        NOTE: This is a placeholder for the actual batch API, assuming standard structure.
        """
        if not self.client:
             raise Exception("GeminiClient not initialized")
        
        # Placeholder for SDK batch implementation
        # Real implementation would likely use self.client.batches.create(...)
        print(f"Batch generation requested for {len(requests)} items on {model}")
        return {"status": "batch_queued", "job_id": "mock_batch_id_123"}

    def get_operation(self, name: str) -> Any:
        """Retrieves an LRO by name.
        
        Uses the SDK's internal methods that accept string operation names
        and return raw dicts, instead of operations.get() which requires
        a typed Operation object with from_api_response().
        """
        print(f"GeminiClient: Getting operation {name}")
        if "projects/" in name or "locations/" in name:
            # Vertex AI path: use _fetch_predict_videos_operation (POST)
            resource_name = name.rpartition("/operations/")[0]
            return self.vertex_client.operations._fetch_predict_videos_operation(
                operation_name=name,
                resource_name=resource_name,
            )
        
        # ML Dev path: use _get_videos_operation (GET)
        return self.client.operations._get_videos_operation(
            operation_name=name,
        )

    def _serialize_response(self, response: Any, depth: int = 0) -> Dict[str, Any]:
        """Serializes GenAI response for Flutter client with extreme resilience."""
        if depth > 10:
            print(f"GeminiClient: Serialization depth exceeded at depth {depth}")
            return {"error": "Serialization depth exceeded"}
            
        if response is None:
            print("GeminiClient: _serialize_response received None response.")
            return {"candidates": [], "error": "Response is None"}
            
        # If response is already a string, don't try to access attributes
        if isinstance(response, str):
            print(f"GeminiClient: _serialize_response received string: {response[:50]}...")
            return {"text": response, "custom_type": "string_result"}

        # Defensive name extraction
        res_name = "unknown"
        try:
            if hasattr(response, 'name'):
                name_val = getattr(response, 'name', "unknown")
                res_name = str(name_val) if name_val is not None else "unknown"
            print(f"GeminiClient: Serializing response with name: {res_name}")
        except Exception as e:
            print(f"GeminiClient: Error extracting response name: {e}")
            pass

        # 1. Handle Operations (LRO)
        # Check for Operation-like structure defensively
        is_op = False
        try:
            is_op = hasattr(response, 'name') and (hasattr(response, 'done') or hasattr(response, 'metadata'))
            if is_op:
                print(f"GeminiClient: Detected LRO for {res_name}")
        except Exception as e:
            print(f"GeminiClient: Error checking for LRO attributes: {e}")
            pass

        if is_op:
            done = False
            try:
                done = getattr(response, 'done', False)
                print(f"GeminiClient: LRO {res_name} done status: {done}")
            except Exception as e:
                print(f"GeminiClient: Error accessing LRO 'done' attribute: {e}")
                pass

            metadata = {}
            try:
                metadata = getattr(response, 'metadata', {})
            except Exception as e:
                print(f"GeminiClient: Error accessing LRO 'metadata' attribute: {e}")
                pass

            result_data = None
            if done:
                print(f"GeminiClient: LRO {res_name} is done, attempting to retrieve result.")
                try:
                    # Some Operation objects might have a result attribute or result() method
                    res_obj = None
                    if hasattr(response, 'result'):
                        attr = getattr(response, 'result')
                        if callable(attr):
                            print(f"GeminiClient: LRO {res_name} result is callable.")
                            res_obj = attr() # It's a method
                        else:
                            print(f"GeminiClient: LRO {res_name} result is an attribute.")
                            res_obj = attr # It's an attribute
                    
                    if res_obj:
                        print(f"GeminiClient: Recursively serializing LRO {res_name} result (type: {type(res_obj)}).")
                        result_data = self._serialize_response(res_obj, depth + 1)
                    else:
                        print(f"GeminiClient: LRO {res_name} result object is None or not found.")
                except Exception as e:
                    print(f"GeminiClient: Error accessing operation result for {res_name}: {e}")
                    result_data = {"error": f"Failed to retrieve result: {str(e)}"}

            return {
                "operationName": res_name,
                "done": done,
                "metadata": str(metadata),
                "custom_type": "veo_lro" if "veo" in res_name.lower() else "lro_op",
                "result": result_data
            }

        # 2. Handle standard GenerateContentResponse / GenerateVideosResponse
        # Check for Veo videos
        try:
            if hasattr(response, 'generated_videos'):
                 print(f"GeminiClient: Detected 'generated_videos' in response.")
                 video_uris = []
                 for v in getattr(response, 'generated_videos', []):
                     v_obj = getattr(v, 'video', None)
                     if v_obj and hasattr(v_obj, 'uri'):
                         video_uris.append(v_obj.uri)
                     elif v_obj and isinstance(v_obj, str):
                         video_uris.append(v_obj)
                 if video_uris:
                     print(f"GeminiClient: Returning Veo result with {len(video_uris)} videos.")
                     return {"videoUri": video_uris[0], "custom_type": "veo_result", "all_videos": video_uris}
        except Exception as e:
            print(f"GeminiClient: Error processing 'generated_videos': {e}")
            pass

        # Check for single video result
        try:
            if hasattr(response, 'video'):
                 print(f"GeminiClient: Detected single 'video' in response.")
                 v = getattr(response, 'video')
                 uri = getattr(v, 'uri', str(v)) if v else None
                 if uri:
                    print(f"GeminiClient: Returning single video result: {uri}")
                    return {"videoUri": uri, "custom_type": "veo_result"}
        except Exception as e:
            print(f"GeminiClient: Error processing single 'video' attribute: {e}")
            pass

        # Check for generated images
        if hasattr(response, 'generated_images'):
            print(f"GeminiClient: Detected 'generated_images' in response.")
            try:
                return self._serialize_images(response)
            except Exception as e:
                print(f"GeminiClient: Error serializing images: {e}")
                pass

        # Check for candidates (standard LLM)
        candidates_data = []
        if hasattr(response, 'candidates') and response.candidates:
            print(f"GeminiClient: Detected {len(response.candidates)} candidates.")
            for cand_idx, cand in enumerate(response.candidates):
                parts_data = []
                content = getattr(cand, 'content', None)
                parts = getattr(content, 'parts', []) if content else []
                
                for part_idx, part in enumerate(parts):
                    if hasattr(part, 'text') and part.text:
                        parts_data.append({"text": part.text})
                    elif hasattr(part, 'thought') and part.thought:
                        parts_data.append({"thought": part.thought})
                    elif hasattr(part, 'function_call') and part.function_call:
                        print(f"GeminiClient: Candidate {cand_idx}, Part {part_idx}: Detected function_call.")
                        fc = part.function_call
                        fc_name = "unknown"
                        try:
                            fc_name = getattr(fc, 'name', "unknown")
                        except Exception as e:
                            print(f"GeminiClient: Error accessing function_call name: {e}")
                            pass
                        
                        fc_args = {}
                        try:
                            fc_args = getattr(fc, 'args', {})
                        except Exception as e:
                            print(f"GeminiClient: Error accessing function_call args: {e}")
                            pass
                        
                        # Convert FC args to serializable dict if not already
                        safe_args = {}
                        try:
                            if hasattr(fc_args, 'items'): # Check if it's a dict-like object
                                for k, v in fc_args.items():
                                    # Convert non-primitive types to string for serialization
                                    safe_args[k] = str(v) if not isinstance(v, (str, int, float, bool, list, dict)) else v
                            else: # Fallback for non-dict-like args
                                safe_args = str(fc_args)
                        except Exception as e:
                            print(f"GeminiClient: Error converting function_call args: {e}")
                            safe_args = {"raw": str(fc_args)}

                        parts_data.append({
                            "call": {
                                "function_name": fc_name,
                                "args": safe_args
                            }
                        })
                    elif hasattr(part, 'executable_code') and part.executable_code:
                         print(f"GeminiClient: Candidate {cand_idx}, Part {part_idx}: Detected executable_code.")
                         parts_data.append({
                             "executable_code": {
                                 "language": getattr(part.executable_code, 'language', 'unknown'),
                                 "code": getattr(part.executable_code, 'code', '')
                             }
                         })
                    elif hasattr(part, 'code_execution_result') and part.code_execution_result:
                         print(f"GeminiClient: Candidate {cand_idx}, Part {part_idx}: Detected code_execution_result.")
                         parts_data.append({
                             "code_execution_result": {
                                 "outcome": getattr(part.code_execution_result, 'outcome', 'UNKNOWN'),
                                 "output": getattr(part.code_execution_result, 'output', '')
                             }
                         })
                    elif hasattr(part, 'inline_data') and part.inline_data:
                         print(f"GeminiClient: Candidate {cand_idx}, Part {part_idx}: Detected inline_data.")
                         parts_data.append({
                             "inlineData": {
                                 "mimeType": part.inline_data.mime_type,
                                 "data": base64.b64encode(part.inline_data.data).decode('utf-8')
                             }
                         })
            
                finish_reason_name = "UNKNOWN"
                try:
                    fr = getattr(cand, 'finish_reason', None)
                    if fr:
                        finish_reason_name = getattr(fr, 'name', str(fr))
                    print(f"GeminiClient: Candidate {cand_idx} finish reason: {finish_reason_name}")
                except Exception as e:
                    print(f"GeminiClient: Error accessing finish_reason for candidate {cand_idx}: {e}")
                    pass

                candidates_data.append({
                    "content": {
                        "parts": parts_data,
                        "role": getattr(cand.content, 'role', "model") if hasattr(cand, 'content') else "model"
                    },
                    "finishReason": finish_reason_name,
                    "groundingMetadata": self._serialize_grounding(cand.grounding_metadata) if hasattr(cand, 'grounding_metadata') and cand.grounding_metadata else None
                })
        else:
            # Check if it's an Interaction response (has outputs instead of candidates)
            if hasattr(response, 'outputs'):
                return self._serialize_interaction(response)
            print("GeminiClient: No candidates or outputs found in response.")

        return {
            "candidates": candidates_data,
            "usageMetadata": self._serialize_usage(response)
        }

    def _serialize_interaction(self, interaction: Any) -> Dict[str, Any]:
        """Serialize an Interaction object from the Interactions API."""
        outputs_data = []
        raw_outputs = getattr(interaction, 'outputs', None) or []
        for output in raw_outputs:
            out_type = getattr(output, 'type', 'unknown')
            item = {"type": out_type}
            
            if out_type == "text":
                item["text"] = getattr(output, 'text', "")
            elif out_type == "thought":
                item["thought"] = getattr(output, 'thought', "")
                item["summary"] = getattr(output, 'summary', "")
            elif out_type == "function_call":
                item["call"] = {
                    "function_name": getattr(output, 'name', "unknown"),
                    "args": getattr(output, 'arguments', {}),
                    "call_id": getattr(output, 'id', None)
                }
            outputs_data.append(item)
            
        # Safely extract status - SDK's Interaction __getattr__ can raise
        # AttributeError even with getattr defaults
        try:
            interaction_status = getattr(interaction, 'state', None)
            if not interaction_status:
                interaction_status = getattr(interaction, 'status', 'unknown')
        except Exception:
            interaction_status = 'unknown'
            
        return {
            "id": getattr(interaction, 'id', None),
            "status": interaction_status,
            "outputs": outputs_data,
            "custom_type": "interaction_result"
        }

    def _serialize_images(self, response: Any) -> Dict[str, Any]:
        image_data = []
        for img in getattr(response, 'generated_images', []):
            # Handle standard google-genai response handling (image_bytes)
            image_bytes = getattr(img.image, 'image_bytes', getattr(img.image, 'data', None))
            if image_bytes:
                image_data.append({
                    "mimeType": img.image.mime_type,
                    "data": base64.b64encode(image_bytes).decode('utf-8')
                })
        return {"images": image_data, "custom_type": "imagen"}

    def _serialize_usage(self, response: Any) -> Dict[str, Any]:
        if not hasattr(response, 'usage_metadata') or not response.usage_metadata:
            return {}
        return {
            "promptTokenCount": response.usage_metadata.prompt_token_count or 0,
            "candidatesTokenCount": response.usage_metadata.candidates_token_count or 0,
            "totalTokenCount": response.usage_metadata.total_token_count or 0,
        }

    def _serialize_grounding(self, metadata: Any) -> Optional[Dict[str, Any]]:
        if not metadata: return None
        return {
            "searchEntryPoint": metadata.search_entry_point.rendered_content if hasattr(metadata.search_entry_point, 'rendered_content') else None,
            "groundingChunks": [
                {"web": {"title": chunk.web.title, "uri": chunk.web.uri}} 
                for chunk in (metadata.grounding_chunks or []) if hasattr(chunk, 'web') and chunk.web
            ]
        }

    def generate_image(self, prompt: str, model: str = "imagen-3.0-fast-generate-001", **kwargs) -> Any:
        """Generate image using legacy Imagen models with fallback."""
        models_to_try = [model, "imagen-3.0-fast-generate-001"]
        models_to_try = list(dict.fromkeys(models_to_try))

        last_error = None
        for attempt_model in models_to_try:
            try:
                print(f"GeminiClient: Attempting image generation with {attempt_model}...")
                return self.vertex_client.models.generate_images(
                    model=self._normalize_model_name(attempt_model),
                    prompt=prompt,
                    config=types.GenerateImagesConfig(**kwargs)
                )
            except Exception as e:
                last_error = e
                print(f"GeminiClient: Image generation failed with {attempt_model}: {e}. Falling back...")
        
        raise last_error or Exception("Image generation failed for all models.")

    def generate_nano_banana(
        self,
        prompt: Union[str, List[Any]],
        model: str = "gemini-2.5-flash-image",
        response_modalities: Optional[List[str]] = None,
        aspect_ratio: Optional[str] = None,
        image_size: Optional[str] = None,
        reference_images: Optional[List[Dict[str, Any]]] = None,
    ) -> Any:
        """Generate images using Nano Banana (gemini-2.5-flash-image) or
        Nano Banana Pro (gemini-3-pro-image-preview) via generate_content.
        
        This is the modern native image generation approach that uses
        generate_content with response_modalities=['Image'] instead of
        the legacy generate_images API.
        """
        normalized_model = self._normalize_model_name(model)
        
        # Build config
        config_params = {}
        
        # Default to returning both text and image
        config_params["response_modalities"] = response_modalities or ["Text", "Image"]
        
        # Image config (aspect ratio, size)
        image_config_params = {}
        if aspect_ratio:
            image_config_params["aspect_ratio"] = aspect_ratio
        if image_size and "pro-image" in normalized_model:
            # image_size only supported on gemini-3-pro-image-preview
            image_config_params["image_size"] = image_size
        if image_config_params:
            config_params["image_config"] = types.ImageConfig(**image_config_params)
        
        config = types.GenerateContentConfig(**config_params)
        
        # Build contents with optional reference images
        contents = []
        if isinstance(prompt, list):
            # Already multipart
            for item in prompt:
                if isinstance(item, dict) and "inline_data" in item:
                    data = item["inline_data"]
                    raw_data = base64.b64decode(data["data"]) if isinstance(data["data"], str) else data["data"]
                    contents.append(types.Part.from_bytes(data=raw_data, mime_type=data["mime_type"]))
                else:
                    contents.append(item)
        else:
            contents.append(prompt)
        
        # Add reference images for editing
        if reference_images:
            for ref_img in reference_images:
                raw_data = base64.b64decode(ref_img["data"]) if isinstance(ref_img["data"], str) else ref_img["data"]
                contents.append(
                    types.Part.from_bytes(
                        data=raw_data,
                        mime_type=ref_img.get("mime_type", "image/png")
                    )
                )
        
        print(f"GeminiClient: Generating Nano Banana image with {normalized_model}...")
        
        # Fallback chain for image models
        fallback_models = [normalized_model, "gemini-2.5-flash-image"]
        fallback_models = list(dict.fromkeys(fallback_models))
        
        last_error = None
        for attempt_model in fallback_models:
            try:
                active_client = self.client
                print(f"GeminiClient: Attempting Nano Banana with {attempt_model}...")
                return active_client.models.generate_content(
                    model=attempt_model,
                    contents=contents,
                    config=config
                )
            except Exception as e:
                last_error = e
                print(f"GeminiClient: Nano Banana failed with {attempt_model}: {e}")
                if any(x in str(e).lower() for x in ["404", "429", "503", "500", "not found"]):
                    continue
                break
        
        raise last_error or Exception("Nano Banana image generation failed.")

    def upload_file(self, file_bytes: bytes, mime_type: str, display_name: Optional[str] = None) -> Any:
        """Upload a file via the Files API for use in generate_content.
        
        Best for large documents (PDFs, videos, etc.) that you want to
        reference across multiple requests without re-uploading.
        """
        print(f"GeminiClient: Uploading file ({mime_type}, {len(file_bytes)} bytes)...")
        
        # The SDK's files.upload expects file-like objects or paths.
        # We use io.BytesIO to wrap raw bytes.
        import io
        file_obj = io.BytesIO(file_bytes)
        
        upload_config = types.UploadFileConfig(mime_type=mime_type)
        if display_name:
            upload_config = types.UploadFileConfig(
                mime_type=mime_type,
                display_name=display_name
            )
        
        uploaded = self.client.files.upload(
            file=file_obj,
            config=upload_config
        )
        
        
        print(f"GeminiClient: File uploaded: {uploaded.name} ({uploaded.uri})")
        return uploaded

    def embed_content(
        self,
        model: str,
        content: Union[str, List[str]],
        task_type: str = "retrieval_document",
        title: Optional[str] = None,
        output_dimensionality: Optional[int] = None
    ) -> List[List[float]]:
        """Generate embeddings for content."""
        model = self._normalize_model_name(model)
        
        # Use Vertex AI for embeddings usually, or Google AI
        client = self.client 
        
        # Determine config
        config_params = {}
        if output_dimensionality:
             config_params["output_dimensionality"] = output_dimensionality

        # Configure task type properly for SDK
        # valid task_types: RETRIEVAL_QUERY, RETRIEVAL_DOCUMENT, SEMANTIC_SIMILARITY, CLASSIFICATION, CLUSTERING
        
        print(f"GeminiClient: Embedding content with {model} (Task: {task_type})...")
        
        try:
            result = client.models.embed_content(
                model=model,
                contents=content,
                config=types.EmbedContentConfig(
                    task_type=task_type,
                    title=title, 
                    **config_params
                )
            )
            
            # Extract embeddings
            embeddings = []
            if hasattr(result, 'embeddings'):
                 for e in result.embeddings:
                     embeddings.append(e.values)
            return embeddings

        except Exception as e:
            print(f"GeminiClient: Embedding failed: {e}")
            raise e



    def get_file(self, file_name: str) -> Any:
        """Get file metadata from the Files API."""
        return self.client.files.get(name=file_name)

    def count_tokens(self, prompt: Union[str, List[Union[str, Any]]], model_name: str = "gemini-2.0-flash") -> int:
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        response = self.client.models.count_tokens(
            model=self._normalize_model_name(model_name),
            contents=prompt
        )
        return response.total_tokens

    def create_interaction(
        self, 
        model: str, 
        prompt: Union[str, List[Any]], 
        system_instruction: Optional[str] = None,
        tools: Optional[List[Any]] = None,
        generation_config: Optional[Dict[str, Any]] = None,
        previous_interaction_id: Optional[str] = None,
        background: bool = False,
        **kwargs
    ) -> Any:
        if not self.client:
            raise Exception("GeminiClient not initialized.")
            
        normalized_model = self._normalize_model_name(model)
        
        # Frontier Deep Research Agent (Jan 2026 standard)
        if "research" in normalized_model.lower() or (isinstance(prompt, str) and "research" in prompt.lower()[:50]):
             print(f"GeminiClient: Triggering Deep Research Agent (Frontier).")
             # Research Agent uses the 'agent' parameter and requires background=True
             return self.client.interactions.create(
                 agent="deep-research-pro-preview-12-2025", 
                 input=prompt,
                 background=True,
                 **kwargs
             )

        # Standard interaction for 2.5/3.0 models
        print(f"GeminiClient: Creating standard interaction with {normalized_model}")
        
        # Handle Thinking Logic for Interactions (Jan 2026)
        thinking_params = None
        if generation_config:
            thinking_level = generation_config.get("thinking_level")
            thinking_summaries = generation_config.get("thinking_summaries")
            
            if thinking_level or thinking_summaries:
                thinking_params = {
                    "level": thinking_level or "medium",
                    "summaries": thinking_summaries or "auto"
                }
                # Clean up generation_config for SDK compatibility
                if "thinking_level" in generation_config: del generation_config["thinking_level"]
                if "thinking_summaries" in generation_config: del generation_config["thinking_summaries"]

        # Prepare params for interactions.create
        params = {
            "model": normalized_model,
            "input": prompt,
            "system_instruction": system_instruction,
            "tools": tools,
            "generation_config": generation_config,
            "previous_interaction_id": previous_interaction_id,
            "background": background,
            "thinking": thinking_params,
            **kwargs
        }
        # Remove None values to avoid SDK errors
        params = {k: v for k, v in params.items() if v is not None}
        
        return self.client.interactions.create(**params)

    def get_interaction(self, id: str) -> Any:
        if not self.client:
             raise Exception("GeminiClient not initialized.")
        return self.client.interactions.get(id=id)
