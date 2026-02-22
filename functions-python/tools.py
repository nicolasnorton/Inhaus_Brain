from google.genai import types
from a2ui_schema import A2UIComponentDef, ComponentParameters, ComponentProperty

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

def get_skill_creator_schema():
    """Returns the tool definition for creating skills from conversation."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="create_skill_from_conversation",
                description="Save a reusable skill or SOP learned from the user. Use this when the user teaches you a repeatable process, checklist, or workflow that should be remembered for future use.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "skill_name": types.Schema(
                            type="STRING",
                            description="Short, lowercase identifier for the skill (e.g. 'seo_audit_checklist')"
                        ),
                        "description": types.Schema(
                            type="STRING",
                            description="One-line summary of what the skill does"
                        ),
                        "content": types.Schema(
                            type="STRING",
                            description="Full markdown instructions for the skill, including steps, rules, and examples"
                        )
                    },
                    required=["skill_name", "description", "content"]
                )
            )
        ]
    )

def get_proposal_generator_schema():
    """Returns the tool definition for generating proposals."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="generate_proposal",
                description="Generate a structured client proposal with scope, deliverables, timeline, and pricing. Returns a formatted proposal document.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "client_name": types.Schema(
                            type="STRING",
                            description="Name of the client or company"
                        ),
                        "project_scope": types.Schema(
                            type="STRING",
                            description="Description of the project scope and objectives"
                        ),
                        "budget_range": types.Schema(
                            type="STRING",
                            description="Budget range or pricing tier (e.g. '$5,000-$10,000')"
                        ),
                        "deliverables": types.Schema(
                            type="ARRAY",
                            items=types.Schema(type="STRING"),
                            description="List of deliverables included in the proposal"
                        ),
                        "timeline_weeks": types.Schema(
                            type="NUMBER",
                            description="Estimated timeline in weeks"
                        )
                    },
                    required=["client_name", "project_scope", "deliverables"]
                )
            )
        ]
    )

def get_video_generation_schema():
    """Returns the tool definition for generating videos."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="video_generation",
                description="Generate a video based on a prompt. Use this when the user asks to create, generate, or make a video.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "prompt": types.Schema(
                            type="STRING",
                            description="The text prompt describing the video content"
                        ),
                        "duration_seconds": types.Schema(
                            type="INTEGER",
                            description="Duration in seconds (default 5)"
                        ),
                        "aspect_ratio": types.Schema(
                            type="STRING",
                            enum=["16:9", "9:16", "1:1"],
                            description="Aspect ratio of the video"
                        )
                    },
                    required=["prompt"]
                )
            )
        ]
    )

def get_deep_research_schema():
    """Returns the tool definition for deep research."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="deep_research",
                description="Start a deep, multi-step research interaction for complex topics that require extensive scanning. Use this when a standard web search is insufficient.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "prompt": types.Schema(
                            type="STRING",
                            description="The high-level research objective or question"
                        ),
                        "aspects": types.Schema(
                            type="ARRAY",
                            items=types.Schema(type="STRING"),
                            description="Specific aspects or sub-topics to investigate"
                        )
                    },
                    required=["prompt"]
                )
            )
        ]
    )

def get_task_orchestration_schema():
    """Returns the tool definition for orchestrating agent tasks."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="orchestrate_task",
                description="Enqueue a task for a specialized agent to process in the background. Use this for parallel workflows or multi-agent campaigns.",
                parameters=types.Schema(
                    type="OBJECT",
                    properties={
                        "agent_name": types.Schema(
                            type="STRING",
                            description="Name of the agent to delegate to (e.g., 'creative', 'copywriter', 'seo')"
                        ),
                        "input": types.Schema(
                            type="STRING",
                            description="The specific prompt or instructions for the agent"
                        ),
                        "metadata": types.Schema(
                            type="OBJECT",
                            description="Optional context or parameters for the task"
                        )
                    },
                    required=["agent_name", "input"]
                )
            )
        ]
    )

def get_a2ui_catalog() -> list[A2UIComponentDef]:
    """Returns the A2UI component catalog for GenUI generation."""
    return [
        A2UIComponentDef(
            name="flightStatus",
            description="Displays the status of a flight, including departure, arrival, and gate information.",
            parameters=ComponentParameters(
                properties={
                    "flightNumber": ComponentProperty(type="string", description="The flight number (e.g., UA123)."),
                    "status": ComponentProperty(type="string", enum=["On Time", "Delayed", "Cancelled", "Boarding"]),
                    "departureTime": ComponentProperty(type="string", description="ISO 8601 formatted departure time."),
                    "arrivalTime": ComponentProperty(type="string", description="ISO 8601 formatted arrival time."),
                    "gate": ComponentProperty(type="string", description="Departure gate.")
                },
                required=["flightNumber", "status", "departureTime"]
            )
        ),
        A2UIComponentDef(
            name="kanbanBoard",
            description="Displays a Kanban board with columns and tasks. Use when the user asks for a project board or task list.",
            parameters=ComponentParameters(
                properties={
                    "title": ComponentProperty(type="string", description="The title of the Kanban board."),
                    "columns": ComponentProperty(
                        type="array",
                        description="The columns in the board.",
                        items={
                            "type": "object",
                            "properties": {
                                "id": {"type": "string"},
                                "title": {"type": "string"},
                                "tasks": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "id": {"type": "string"},
                                            "title": {"type": "string"},
                                            "description": {"type": "string"}
                                        },
                                        "required": ["id", "title"]
                                    }
                                }
                            },
                            "required": ["id", "title"]
                        }
                    )
                },
                required=["title", "columns"]
            )
        ),
        A2UIComponentDef(
            name="checklist",
            description="Displays an interactive checklist.",
            parameters=ComponentParameters(
                properties={
                    "title": ComponentProperty(type="string", description="The title of the checklist."),
                    "items": ComponentProperty(
                        type="array",
                        description="The items in the checklist.",
                        items={
                            "type": "object",
                            "properties": {
                                "id": {"type": "string"},
                                "text": {"type": "string"},
                                "isCompleted": {"type": "boolean"}
                            },
                            "required": ["id", "text", "isCompleted"]
                        }
                    )
                },
                required=["title", "items"]
            )
        )
    ]
