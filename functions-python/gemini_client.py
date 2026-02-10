import os
from google import genai
from google.genai import types
from typing import Optional, List, Union, Dict, Any

class GeminiClient:
    """Wrapper for Google GenAI SDK (Modern v1)."""
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Gemini Client.
        
        Args:
            api_key: Optional API key. If not provided, attempts to read from GOOGLE_API_KEY environment variable.
        """
        self.api_key = api_key or os.environ.get("GOOGLE_API_KEY")
        if not self.api_key:
            print("Warning: GOOGLE_API_KEY not found in environment.")
        
        # Initialize the new Client
        self.client = genai.Client(api_key=self.api_key) if self.api_key else None

    def generate_content(
        self, 
        prompt: Union[str, List[Union[str, Any]]], 
        model_name: str = "gemini-1.5-flash",
        generation_config: Optional[Dict[str, Any]] = None,
        stream: bool = False,
        system_instruction: Optional[str] = None,
        tools: Optional[List[Any]] = None,
        thinking: bool = False,
        audio: bool = False
    ) -> Any:
        """
        Generate content using the specified model.
        
        Args:
            prompt: The input prompt (string or list of parts).
            model_name: Model to use.
            generation_config: Configuration for generation (temperature, etc).
            stream: Whether to stream the response.
            system_instruction: Optional system instruction.
            tools: Optional list of tools (functions, google search, etc).
            thinking: Whether to enable thinking mode.
            
        Returns:
            The generation response.
        """
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")

        # Prepare generation config
        config_params = (generation_config or {}).copy()
        
        # Handle thinking mode
        thinking_config = None
        if thinking:
            thinking_config = types.ThinkingConfig(include_thoughts=True)
            # Remove from config_params if it was passed there too
            config_params.pop("thinking_config", None)

        # Handle tools conversion from dict to types.Tool
        processed_tools = None
        if tools:
            processed_tools = []
            for tool in tools:
                if isinstance(tool, dict):
                    # Grounding: Google Search
                    if "google_search" in tool or "web_search" in tool:
                        processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    # Grounding: Google Maps
                    elif "google_maps" in tool or "googleMaps" in tool:
                        processed_tools.append(types.Tool(google_maps=types.GoogleMaps()))
                    # Code Execution
                    elif "code_execution" in tool:
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    # Computer Use
                    elif "computer_use" in tool:
                        processed_tools.append(types.Tool(computer_use=types.ComputerUse()))
                    # Function Calling (Declarations)
                    elif "function_declarations" in tool:
                        decls = [types.FunctionDeclaration(**d) for d in tool["function_declarations"]]
                        processed_tools.append(types.Tool(function_declarations=decls))
                    else:
                        processed_tools.append(tool)
                elif isinstance(tool, str):
                     # Handle common string-based tool aliases
                    if tool in ["google_search", "web_search"]:
                        processed_tools.append(types.Tool(google_search=types.GoogleSearch()))
                    elif tool in ["google_maps", "googleMaps"]:
                        processed_tools.append(types.Tool(google_maps=types.GoogleMaps()))
                    elif tool == "code_execution":
                        processed_tools.append(types.Tool(code_execution=types.CodeExecution()))
                    else:
                        # For now, if it's an unknown string, we keep it (might be a system tool)
                        processed_tools.append(tool)
                else:
                    processed_tools.append(tool)

        # Handle Audio Modality
        if audio:
            config_params["response_modalities"] = ["AUDIO"]

        # Construct the final config
        config = types.GenerateContentConfig(
            system_instruction=system_instruction,
            tools=processed_tools,
            thinking_config=thinking_config,
            **config_params
        )

        # Process prompt if it's a list (handle multimodal parts)
        processed_contents = prompt
        if isinstance(prompt, list):
            processed_contents = []
            for item in prompt:
                if isinstance(item, dict):
                    # Handle multimodal dictionaries (e.g., {"mime_type": "image/jpeg", "data": "..."})
                    if "inline_data" in item:
                        data = item["inline_data"]
                        processed_contents.append(types.Part.from_bytes(
                            data=data["data"], 
                            mime_type=data["mime_type"]
                        ))
                    elif "file_data" in item:
                        file_data = item["file_data"]
                        processed_contents.append(types.Part.from_uri(
                            file_uri=file_data["file_uri"],
                            mime_type=file_data["mime_type"]
                        ))
                    else:
                        processed_contents.append(item)
                else:
                    processed_contents.append(item)

        if stream:
            return self.client.models.generate_content_stream(
                model=model_name,
                contents=processed_contents,
                config=config
            )
        else:
            return self.client.models.generate_content(
                model=model_name,
                contents=processed_contents,
                config=config
            )

    def generate_image(self, prompt: str, model: str = "imagen-3", **kwargs) -> Any:
        """Generate an image using Imagen."""
        if not self.client:
             raise Exception("GeminiClient not initialized with API Key.")
        return self.client.models.generate_image(
            model=model,
            prompt=prompt,
            config=types.GenerateImageConfig(**kwargs)
        )

    def count_tokens(self, prompt: Union[str, List[Union[str, Any]]], model_name: str = "gemini-1.5-flash") -> int:
        """Count tokens for the given prompt."""
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")
            
        response = self.client.models.count_tokens(
            model=model_name,
            contents=prompt
        )
        return response.total_tokens

    def create_interaction(self, model: str, prompt: str, **kwargs) -> Any:
        """Create a deep research interaction."""
        if not self.client:
            raise Exception("GeminiClient not initialized.")
        return self.client.interactions.create(
             model=model,
             contents=prompt,
             **kwargs
        )

    def get_interaction(self, id: str) -> Any:
        """Get the status/result of a deep research interaction."""
        if not self.client:
             raise Exception("GeminiClient not initialized.")
        return self.client.interactions.get(id=id)

    def upload_file(self, path: str, mime_type: Optional[str] = None, display_name: Optional[str] = None) -> Any:
        """Upload a file to the File API."""
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")
        return self.client.files.upload(path=path, config=types.UploadFileConfig(mime_type=mime_type, display_name=display_name))

    def get_file(self, name: str) -> Any:
        """Get a file from the File API."""
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")
        return self.client.files.get(name=name)

    def delete_file(self, name: str) -> None:
        """Delete a file from the File API."""
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")
        self.client.files.delete(name=name)
