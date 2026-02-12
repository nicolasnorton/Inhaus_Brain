from google.genai import types

def get_weather_schema():
    """Returns the tool definition for weather lookups."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="get_weather",
                description="Get the current weather in a given location.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "location": types.Schema(
                            type="STRING",
                            description="The city and state, e.g. San Francisco, CA"
                        ),
                        "unit": types.Schema(
                            type="STRING",
                            enum=["celsius", "fahrenheit"],
                            description="The unit of temperature"
                        )
                    },
                    required=["location"]
                )
            )
        ]
    )

def get_charts_schema():
    """Returns the tool definition for generating charts."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="generate_chart",
                description="Generate a chart based on provided data points.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "title": types.Schema(type="STRING", description="Chat title"),
                        "chart_type": types.Schema(
                            type="STRING",
                            enum=["line", "bar", "pie"],
                            description="Type of chart to render"
                        ),
                        "data": types.Schema(
                            type="ARRAY",
                            items=types.Schema(
                                type="OBJECT",
                                properties={
                                    "label": types.Schema(type="STRING"),
                                    "value": types.Schema(type="NUMBER")
                                }
                            ),
                            description="Data points for the chart"
                        )
                    },
                    required=["title", "chart_type", "data"]
                )
            )
        ]
    )

def get_meetings_schema():
    """Returns the tool definition for meeting scheduling."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="schedule_meeting",
                description="Schedule a meeting in the user's calendar.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "summary": types.Schema(type="STRING", description="Meeting title"),
                        "start_time": types.Schema(
                            type="STRING",
                            description="Start time in ISO 8601 format"
                        ),
                        "end_time": types.Schema(
                            type="STRING",
                            description="End time in ISO 8601 format"
                        ),
                        "attendees": types.Schema(
                            type="ARRAY",
                            items=types.Schema(type="STRING"),
                            description="List of email addresses"
                        )
                    },
                    required=["summary", "start_time", "end_time"]
                )
            )
        ]
    )

def get_image_generation_schema():
    """Returns the tool definition for image generation."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="image_generation",
                description="Generate a production-grade image concept.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "prompt": types.Schema(
                            type="STRING",
                            description="The prompt to generate the image for."
                        )
                    },
                    required=["prompt"]
                )
            )
        ]
    )

def get_video_generation_schema():
    """Returns the tool definition for video generation."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="video_generation",
                description="Generate a high-fidelity video asset.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "prompt": types.Schema(
                            type="STRING",
                            description="The prompt to generate the video for."
                        ),
                        "model_id": types.Schema(
                            type="STRING",
                            description="Optional. Specific Veo model ID (e.g., veo-3.1-generate-preview, veo-2.0-generate-001)."
                        ),
                        "is_final": types.Schema(
                            type="BOOLEAN",
                            description="Whether to generate a high-quality final render (slower) or a preview."
                        )
                    },
                    required=["prompt"]
                )
            )
        ]
    )

def get_audio_generation_schema():
    """Returns the tool definition for audio generation."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="audio_generation",
                description="Compose advanced music or soundtracks.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "prompt": types.Schema(
                            type="STRING",
                            description="The prompt to compose audio for."
                        )
                    },
                    required=["prompt"]
                )
            )
        ]
    )
