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
        system_instruction: Optional[str] = None
    ) -> Any:
        """
        Generate content using the specified model.
        
        Args:
            prompt: The input prompt (string or list of parts).
            model_name: Model to use.
            generation_config: Configuration for generation (temperature, etc).
            stream: Whether to stream the response.
            system_instruction: Optional system instruction.
            
        Returns:
            The generation response.
        """
        if not self.client:
            raise Exception("GeminiClient not initialized with API Key.")

        # Convert generation_config dict to GenerateContentConfig if provided
        config = None
        if generation_config or system_instruction:
            config = types.GenerateContentConfig(
                system_instruction=system_instruction,
                **(generation_config or {})
            )

        if stream:
            return self.client.models.generate_content_stream(
                model=model_name,
                contents=prompt,
                config=config
            )
        else:
            return self.client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=config
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
