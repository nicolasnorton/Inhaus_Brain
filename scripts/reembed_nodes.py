"""
BrainWeave 2.0 — Embeddings Normalization
Fixes 'Array length mismatch: 3072 and 768' by re-embedding all nodes
in Spanner using the new `text-embedding-005` model (768 dims).
"""
import os
from google.cloud import spanner
import vertexai
from vertexai.language_models import TextEmbeddingModel

PROJECT = "inhausbrain"
INSTANCE = "brainweave-graph"
DB = "brainweave"

vertexai.init(project=PROJECT)
embed_model = TextEmbeddingModel.from_pretrained("text-embedding-005")
spanner_client = spanner.Client(project=PROJECT)
database = spanner_client.instance(INSTANCE).database(DB)

def _get_embedding(text: str) -> list[float]:
    result = embed_model.get_embeddings([text[:2000]])
    return result[0].values if result else []

with database.snapshot() as snapshot:
    nodes = list(snapshot.execute_sql("SELECT node_id, title, description, content FROM BrainWeaveNodes"))

print(f"Found {len(nodes)} nodes to re-embed.")

for count, (node_id, title, description, content) in enumerate(nodes, 1):
    embed_text = f"{title} {description} {content[:500]}"
    try:
        new_emb = _get_embedding(embed_text)
        new_emb_f32 = [float(x) for x in new_emb]
        
        def update_node(transaction):
            transaction.update(
                "BrainWeaveNodes",
                columns=["node_id", "embedding"],
                values=[[node_id, new_emb_f32]]
            )
        
        database.run_in_transaction(update_node)
        print(f"[{count}/{len(nodes)}] Re-embedded: {title} (len: {len(new_emb)})")
    except Exception as e:
        print(f"Failed to embed node {node_id}: {e}")

print("Done re-embedding nodes.")
