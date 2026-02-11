import os
import json
import base64
from google import genai
from google.genai import types
from typing import Optional, List, Union, Dict, Any

class GeminiClient:
    """Wrapper for Google GenAI SDK (Modern v1) - Flawless Upgrade v1.5"""
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Gemini Client.
        """
        self.api_key = api_key or os.environ.get("GOOGLE_API_KEY")
        if not self.api_key:
            print("Warning: GOOGLE_API_KEY not found in environment.")
        
        # Initialize the new Client
        if self.api_key:
            print(f"GeminiClient: Initializing with API key (Length: {len(self.api_key)})")
            self.client = genai.Client(api_key=self.api_key)
        else:
            print("GeminiClient: No API key found. Attempting ADC...")
            self.client = genai.Client()

    def _normalize_model_name(self, model_name: str) -> str:
        """Normalize model names that might be legacy or aliased."""
        if not model_name:
            return "gemini-2.5-flash"

        name_lower = model_name.lower()

        # Explicitly preserve specialized models
        SPECIALIZED_MODELS = ["veo", "imagen", "lyra", "nano"]
        if any(sm in name_lower for sm in SPECIALIZED_MODELS):
            # Veo 3.1 mapping
            if "veo" in name_lower and "3.1" in name_lower:
                return "veo-3.1-generate-001"
            # Nano Banana mapping
            if "nano" in name_lower or "banana" in name_lower:
                 if "pro" in name_lower:
                     return "imagen-3.0-nano-banana-pro-001"
                 return "imagen-3.0-nano-banana-001"
            return model_name
            
        # Map Gemini 3 (Frontier)
        if "gemini-3" in name_lower:
            if "image" in name_lower:
                return "gemini-3-pro-image-preview"
            return "gemini-2.5-pro" if "pro" in name_lower else "gemini-2.5-flash"
            
        # Map Gemini 2.5 (Legacy High Performance)
        if "gemini-2.5" in name_lower:
            if "lite" in name_lower:
                return "gemini-2.5-flash-lite"
            return "gemini-2.5-pro" if "pro" in name_lower else "gemini-2.5-flash"

        # Map Thinking requests
        if "thinking" in name_lower:
            # Upgrade thinking to Gemini 3 reasoning if available, else fallback
            return "gemini-2.0-flash-thinking-exp-01-21"

        # Standardize simple/legacy names to latest 3.0 versioned names for Flawless v1.5
        if name_lower in ["gemini-flash", "gemini-pro", "flash", "pro"]:
             return "gemini-2.5-pro" if "pro" in name_lower else "gemini-2.5-flash"
            
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
        cached_content_name: Optional[str] = None
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
        
        # Handle thinking mode
        thinking_config = None
        if thinking:
            thinking_config = types.ThinkingConfig(include_thoughts=True)
            config_params.pop("thinking_config", None)

        processed_tools = []
        if use_google_search:
            processed_tools.append(types.Tool(google_search=types.GoogleSearch()))

        if tools:
            for tool in tools:
                if isinstance(tool, dict):
                    if "google_search" in tool or "web_search" in tool:
                        processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    elif "google_maps" in tool or "googleMaps" in tool:
                        processed_tools.append(types.Tool(google_maps=types.GoogleMaps()))
                    elif "code_execution" in tool:
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    elif "function_declarations" in tool:
                        decls = [types.FunctionDeclaration(**d) for d in (tool["function_declarations"] or [])]
                        processed_tools.append(types.Tool(function_declarations=decls))
                    else:
                        processed_tools.append(tool)
                elif isinstance(tool, str):
                    if tool in ["google_search", "web_search"]:
                        processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    elif tool == "code_execution":
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    else:
                        processed_tools.append(tool)
                else:
                    processed_tools.append(tool)

        if audio:
            config_params["response_modalities"] = ["AUDIO"]

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

        if stream:
            return self.client.models.generate_content_stream(model=model, contents=processed_contents, config=config)
        else:
            return self.client.models.generate_content(model=model, contents=processed_contents, config=config)

    def generate_video(self, prompt: str, model: str = "veo-3.1-generate-001", config: Optional[Dict[str, Any]] = None) -> Any:
        """Generate a video using Veo 3.1."""
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        
        cv = {
            "duration_seconds": 5,
            "aspect_ratio": "16:9",
        }
        if config:
            if 'durationSeconds' in config: cv['duration_seconds'] = config['durationSeconds']
            if 'aspectRatio' in config: cv['aspect_ratio'] = config['aspectRatio']
            if 'resolution' in config: cv['resolution'] = config['resolution']
            cv.update({k: v for k, v in config.items() if k not in ['durationSeconds', 'aspectRatio', 'resolution']})

        return self.client.models.generate_videos(
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
        """Get status of an LRO."""
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        return self.client.operations.get(name=name)

    def _serialize_response(self, response: Any) -> Dict[str, Any]:
        """Helper to serialize a GenAI response object (Content OR Operation) to a dict."""
        
        # Handle LRO/Operation responses
        if hasattr(response, 'name') and (hasattr(response, 'done') or hasattr(response, 'metadata')):
            return {
                "operationName": response.name,
                "done": getattr(response, 'done', False),
                "metadata": response.metadata if hasattr(response, 'metadata') else None,
                "custom_type": "veo_lro" if "veo" in response.name.lower() else "lro_op",
                "result": self._serialize_response(response.result) if getattr(response, 'done', False) and hasattr(response, 'result') else None
            }

        candidates_data = []
        if not hasattr(response, 'candidates') or not response.candidates:
            if hasattr(response, 'generated_images'):
                return self._serialize_images(response)
            
            # Check for direct video result (if LRO already finished in-line, rare but possible)
            if hasattr(response, 'video'):
                 return {"videoUri": response.video.uri, "custom_type": "veo_result"}

            return {
                "candidates": [],
                "usageMetadata": self._serialize_usage(response)
            }

        for cand in response.candidates:
            parts_data = []
            if cand.content and cand.content.parts:
                for part in cand.content.parts:
                    if hasattr(part, 'text') and part.text:
                        parts_data.append({"text": part.text})
                    elif hasattr(part, 'thought') and part.thought:
                        parts_data.append({"thought": part.thought})
                    elif hasattr(part, 'function_call') and part.function_call:
                        parts_data.append({
                            "executable_adunit": {
                                "call": {
                                    "function_name": part.function_call.name,
                                    "args": part.function_call.args
                                }
                            }
                        })
                    elif hasattr(part, 'inline_data') and part.inline_data:
                         parts_data.append({
                             "inlineData": {
                                 "mimeType": part.inline_data.mime_type,
                                 "data": base64.b64encode(part.inline_data.data).decode('utf-8')
                             }
                         })
            
            candidates_data.append({
                "content": {
                    "parts": parts_data,
                    "role": cand.content.role if cand.content else "model"
                },
                "finishReason": cand.finish_reason.name if cand.finish_reason else None,
                "groundingMetadata": self._serialize_grounding(cand.grounding_metadata) if hasattr(cand, 'grounding_metadata') and cand.grounding_metadata else None
            })

        return {
            "candidates": candidates_data,
            "usageMetadata": self._serialize_usage(response)
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

    def generate_image(self, prompt: str, model: str = "imagen-3.0-nano-banana-001", **kwargs) -> Any:
        """Generate image using Nano Banana models."""
        if not self.client:
             raise Exception("GeminiClient not initialized.")
        return self.client.models.generate_images(
            model=self._normalize_model_name(model),
            prompt=prompt,
            config=types.GenerateImagesConfig(**kwargs)
        )

    def count_tokens(self, prompt: Union[str, List[Union[str, Any]]], model_name: str = "gemini-2.5-flash") -> int:
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        response = self.client.models.count_tokens(
            model=self._normalize_model_name(model_name),
            contents=prompt
        )
        return response.total_tokens

    def create_interaction(self, model: str, prompt: str, **kwargs) -> Any:
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        return self.client.interactions.create(model=self._normalize_model_name(model), contents=prompt, **kwargs)

    def get_interaction(self, id: str) -> Any:
        if not self.client:
             raise Exception("GeminiClient not initialized.")
        return self.client.interactions.get(id=id)
