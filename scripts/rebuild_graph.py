"""
BrainWeave 2.1 Context-Hub Upgrade - Graph Rebuild Migration Script
Forces a complete rebuild of the knowledge graphs for all users by pulling down their
GCS Markdown vaults and re-running them through the chunking/embedding pipeline.
"""

import os
import json
import uuid
from google.cloud import storage, spanner

PROJECT = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB = os.environ.get("SPANNER_DB", "brainweave")
BUCKET_NAME = f"{PROJECT}-brainweave-vault"

def rebuild_all_graphs():
    print("Initiating global knowledge graph rebuild...")
    
    # 1. Connect to Spanner
    spanner_client = spanner.Client(project=PROJECT)
    database = spanner_client.instance(INSTANCE).database(DB)
    
    # 2. Connect to GCS
    try:
        storage_client = storage.Client(project=PROJECT)
        bucket = storage_client.bucket(BUCKET_NAME)
    except Exception as e:
        print(f"Failed to connect to GCS bucket {BUCKET_NAME}: {e}")
        return
    
    # 3. List all markdown files (assuming structure like {user_id}/{filename}.md)
    blobs = bucket.list_blobs()
    count = 0
    for blob in blobs:
        if not blob.name.endswith('.md'):
            continue
            
        print(f"Processing {blob.name}...")
        try:
            content = blob.download_as_text()
            user_id = blob.name.split('/')[0]
            title = blob.name.split('/')[-1].replace('.md', '')
            node_id = str(uuid.uuid4())
            
            # Simple chunking for migration (in production this calls Vertex AI to chunk)
            desc = content[:200]
            
            # 4. Write back to Spanner via transaction
            def write_txn(transaction):
                transaction.insert_or_update(
                    "BrainWeaveNodes",
                    columns=["node_id", "owner_id", "title", "description", "content", "node_type", "scope", "created_at", "updated_at"],
                    values=[[node_id, user_id, title[:200], desc[:200], content, "atomic", "PRIVATE", spanner.COMMIT_TIMESTAMP, spanner.COMMIT_TIMESTAMP]]
                )
            
            database.run_in_transaction(write_txn)
            print(f"Successfully re-indexed {blob.name}")
            count += 1
            
        except Exception as e:
            print(f"Error processing {blob.name}: {e}")
            
    print(f"Rebuild complete. {count} files processed.")

if __name__ == "__main__":
    rebuild_all_graphs()
