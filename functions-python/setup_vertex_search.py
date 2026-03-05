import os
from google.cloud import discoveryengine

project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "inhausbrain")
location = "global"

def create_data_store(client, data_store_id, display_name, content_config):
    parent = f"projects/{project_id}/locations/{location}/collections/default_collection"
    
    data_store = discoveryengine.DataStore(
        display_name=display_name,
        industry_vertical=discoveryengine.IndustryVertical.GENERIC,
        content_config=content_config
    )
    
    request = discoveryengine.CreateDataStoreRequest(
        parent=parent,
        data_store=data_store,
        data_store_id=data_store_id
    )
    
    print(f"Creating DataStore {data_store_id}...")
    try:
         operation = client.create_data_store(request=request)
         response = operation.result()
         print(f"Created DataStore: {response.name}")
         return response.name
    except Exception as e:
         print(f"DataStore {data_store_id} might already exist or error: {e}")
         return f"{parent}/dataStores/{data_store_id}"

def main():
    client = discoveryengine.DataStoreServiceClient()
    
    # Create the Unstructured Data Store for ingested reports & research
    create_data_store(
        client, 
        "brainweave-knowledge", 
        "BrainWeave Organized Knowledge", 
        discoveryengine.DataStore.ContentConfig.CONTENT_REQUIRED
    )
    
    # Create the Web Search Data Store for the Gemini Agent's Deep Research grounding
    # We use PUBLIC_WEBSITE and set the flag for public Google Search
    create_data_store(
        client, 
        "brainweave-discovery", 
        "BrainWeave Discovery Engine", 
        discoveryengine.DataStore.ContentConfig.PUBLIC_WEBSITE
    )

if __name__ == "__main__":
    main()
