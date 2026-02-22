import os
from google import genai
from google.genai import types

def test_tool():
    client = genai.Client(vertexai=True, project=os.environ.get("GOOGLE_CLOUD_PROJECT", "inhausbrain"), location="us-central1")
    
    # Simulate the tool schema from flutter
    flutter_tool = {
        "name": "gen_ui_component",
        "description": "Renders a component",
        "parameters": {
            "type": "object",
            "properties": {
                "component_type": {"type": "string"},
                "data": {"type": "object", "description": "some data"},
                "summary_text": {"type": "string"}
            },
            "required": ["component_type", "data"]
        }
    }
    
    t = types.Tool(function_declarations=[flutter_tool])
    config = types.GenerateContentConfig(
        tools=[t],
        temperature=0.0
    )
    
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents="Generate a gen_ui_component for a budget_chart with data: {\"some_unknown_field\": \"foo\", \"deep\": {\"nested\": 1}}.",
        config=config
    )
    
    print(response.text)
    if response.function_calls:
        print("Function Calls:", response.function_calls)
    else:
        print("Finish Reason:", response.candidates[0].finish_reason)

if __name__ == "__main__":
    test_tool()
