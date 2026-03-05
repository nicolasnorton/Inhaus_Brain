import os
from google.cloud import discoveryengine

project_id = "1096509611056"
location = "global"
data_store_id = "brainweave-knowledge"

client = discoveryengine.DocumentServiceClient()
parent = client.branch_path(
    project=project_id,
    location=location,
    data_store=data_store_id,
    branch="default_branch",
)

document = discoveryengine.Document(
    id="test-combined-123",
    struct_data={
        "title": "BrainWeave Deep Research Test",
    },
    content=discoveryengine.Document.Content(
        mime_type="text/plain",
        raw_bytes=b"This is the actual text content of the deep research report. Combining struct_data and content!",
    )
)

request = discoveryengine.CreateDocumentRequest(
    parent=parent,
    document=document,
    document_id="test-combined-123",
)

try:
    response = client.create_document(request=request)
    print("Success:", response.name)
except Exception as e:
    print("Error:", e)
