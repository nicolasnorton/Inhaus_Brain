import os
from google import genai
from google.genai import types

def main():
    client = genai.Client(vertexai=True, project="inhausbrain", location="us-central1")
    datastore_id = "projects/1096509611056/locations/global/collections/default_collection/dataStores/brainweave-discovery"
    vertex_search = types.VertexAISearch(datastore=datastore_id)
    retrieval_tool = types.Tool(
        retrieval=types.Retrieval(vertex_ai_search=vertex_search)
    )

    try:
        interaction = client.models.create_interaction(
            model="gemini-deep-research-pro-preview-12-2025",
            # prompt="Write a short report about Vertex AI search.",
            config=types.InteractionConfig(
                display_name="Test interaction",
                tools=[retrieval_tool],
            )
        )
        print("Success:", interaction)
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    main()
