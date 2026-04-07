import os
import json
import traceback
from google.cloud import spanner
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

# Mocking the environment
os.environ["GCP_PROJECT"] = "inhausbrain"
os.environ["SPANNER_INSTANCE"] = "brainweave-graph"
os.environ["SPANNER_DB"] = "brainweave"

PROJECT = "inhausbrain"
INSTANCE = "brainweave-graph"
DB = "brainweave"

client = spanner.Client(project=PROJECT)
database = client.instance(INSTANCE).database(DB)

def get_graph_data(owner_id):
    try:
        # 1. Fetch nodes
        with database.snapshot() as snapshot:
            node_results = list(snapshot.execute_sql(
                "SELECT node_id, title, description, content, node_type, topics, scope, confidence, metadata "
                "FROM BrainWeaveNodes WHERE owner_id = @oid",
                params={"oid": owner_id},
                param_types={"oid": spanner.param_types.STRING},
            ))
            
        nodes = []
        for r in node_results:
            nodes.append({
                "node_id": r[0],
                "title": r[1],
                "description": r[2],
                "content": r[3],
                "node_type": r[4],
                "topics": list(r[5]) if r[5] else [],
                "scope": r[6],
                "confidence": r[7],
                "metadata": r[8] if r[8] else {},
            })
            
        # 2. Fetch edges
        with database.snapshot() as snapshot:
            edge_results = list(snapshot.execute_sql(
                "SELECT edge_id, source_node_id, target_node_id, relationship_type "
                "FROM BrainWeaveEdges WHERE owner_id = @oid",
                params={"oid": owner_id},
                param_types={"oid": spanner.param_types.STRING},
            ))
            
        edges = []
        for r in edge_results:
            edges.append({
                "edge_id": r[0],
                "source_node_id": r[1],
                "target_node_id": r[2],
                "relationship_type": r[3],
            })
            
        return {
            "nodes": nodes,
            "edges": edges,
            "count_nodes": len(nodes),
            "count_edges": len(edges)
        }
    except Exception as e:
        print(f"Error: {e}")
        # traceback.print_exc()
        return None

if __name__ == "__main__":
    owner_id = "I52W9ogEVuY5ccttEXk4H0ht46B2"
    print(f"Testing for owner_id: {owner_id}")
    data = get_graph_data(owner_id)
    if data:
        print(f"Success! Nodes: {data['count_nodes']}, Edges: {data['count_edges']}")
    else:
        print("Failed to fetch data.")
