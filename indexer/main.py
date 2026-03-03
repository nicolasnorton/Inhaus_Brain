"""
BrainWeave 2.0 Indexer — Cloud Run Service
Listens for Cloud Storage Pub/Sub notifications when new Markdown files
land in the vault. Extracts structured graph data via Gemini and writes
to Cloud Spanner.
"""
import json
import os
import base64
import uuid
from datetime import datetime

from flask import Flask, request, jsonify
from google.cloud import spanner, storage

import vertexai
from vertexai.generative_models import GenerativeModel
from vertexai.language_models import TextEmbeddingModel

app = Flask(__name__)

PROJECT    = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE   = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB         = os.environ.get("SPANNER_DB", "brainweave")
MODEL_ID   = os.environ.get("GEMINI_MODEL", "gemini-3.1-pro")
EMBED_ID   = os.environ.get("EMBED_MODEL", "text-embedding-005")

# Init clients
vertexai.init(project=PROJECT)
spanner_client = spanner.Client(project=PROJECT)
database = spanner_client.instance(INSTANCE).database(DB)
gcs = storage.Client(project=PROJECT)
model = GenerativeModel(MODEL_ID)
embed_model = TextEmbeddingModel.from_pretrained(EMBED_ID)

EXTRACTION_PROMPT = """
You are the BrainWeave Indexer — a structured knowledge extraction engine.

Given this Markdown document from a knowledge vault, extract structured graph data.
Analyze the content carefully and identify:
1. The primary concept (node) described
2. Any explicit or implicit connections to other concepts (edges)

Return ONLY valid JSON with this exact structure:
{{
  "node": {{
    "title": "Clear, descriptive title",
    "description": "1-2 sentence summary of the key insight",
    "content": "Full extracted content (cleaned up, no frontmatter)",
    "node_type": "atomic|moc|topic|campaign|client|insight|asset|trend",
    "topics": ["topic1", "topic2"],
    "confidence": 0.95
  }},
  "edges": [
    {{
      "target_title": "Title of the related concept",
      "relationship_type": "influences|part_of|impacts|extends|contradicts",
      "weight": 0.8
    }}
  ]
}}

Document:
---
{content}
---
"""


@app.route("/", methods=["POST"])
def handle_pubsub():
    """Handle Pub/Sub push from Cloud Storage notification."""
    try:
        envelope = request.get_json()
        if not envelope or "message" not in envelope:
            return "Bad Request: no Pub/Sub message", 400

        message = envelope["message"]
        data = json.loads(base64.b64decode(message["data"]))

        bucket_name = data.get("bucket")
        object_name = data.get("name")

        if not bucket_name or not object_name:
            return "Bad Request: missing bucket/name", 400

        # Skip non-markdown files
        if not object_name.endswith(".md"):
            return "Skipped: not a Markdown file", 200

        # 1. Read the Markdown from GCS
        bucket = gcs.bucket(bucket_name)
        blob = bucket.blob(object_name)
        md_content = blob.download_as_text()

        # 2. Extract owner_id from path: {owner_id}/weave/...
        path_parts = object_name.split("/")
        owner_id = path_parts[0] if len(path_parts) > 1 else "unknown"

        # 3. Call Gemini for structured extraction
        response = model.generate_content(
            EXTRACTION_PROMPT.format(content=md_content)
        )
        extracted = json.loads(response.text)

        # 4. Generate embedding
        text_to_embed = (
            f"{extracted['node']['title']} "
            f"{extracted['node']['description']} "
            f"{extracted['node']['content'][:500]}"
        )
        embeddings = embed_model.get_embeddings([text_to_embed])
        embedding_vector = embeddings[0].values if embeddings else []

        # 5. Write node to Spanner
        node_id = str(uuid.uuid4())
        node_data = extracted["node"]

        def write_node(transaction):
            transaction.insert(
                "BrainWeaveNodes",
                columns=[
                    "node_id", "owner_id", "title", "description",
                    "content", "node_type", "topics", "embedding",
                    "markdown_uri", "source_agent", "confidence",
                    "created_at", "updated_at",
                ],
                values=[[
                    node_id, owner_id,
                    node_data["title"],
                    node_data.get("description", ""),
                    node_data.get("content", ""),
                    node_data.get("node_type", "atomic"),
                    node_data.get("topics", []),
                    embedding_vector,
                    f"gs://{bucket_name}/{object_name}",
                    "indexer",
                    node_data.get("confidence", 1.0),
                    spanner.COMMIT_TIMESTAMP,
                    spanner.COMMIT_TIMESTAMP,
                ]],
            )

        database.run_in_transaction(write_node)

        # 6. Resolve and write edges (best-effort title matching)
        for edge in extracted.get("edges", []):
            _create_edge(owner_id, node_id, edge)

        app.logger.info(f"Indexed: {node_data['title']} ({node_id})")
        return jsonify({"status": "ok", "node_id": node_id}), 200

    except Exception as e:
        app.logger.error(f"Indexer error: {e}")
        return jsonify({"error": str(e)}), 500


def _create_edge(owner_id: str, source_id: str, edge_data: dict):
    """Resolve target node by title and create an edge."""
    target_title = edge_data.get("target_title", "")
    if not target_title:
        return

    # Find target node by title (best-effort fuzzy match)
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(
            "SELECT node_id FROM BrainWeaveNodes "
            "WHERE owner_id = @owner AND title = @title LIMIT 1",
            params={"owner": owner_id, "title": target_title},
            param_types={
                "owner": spanner.param_types.STRING,
                "title": spanner.param_types.STRING,
            },
        )
        rows = list(results)

    if not rows:
        return

    target_id = rows[0][0]
    edge_id = str(uuid.uuid4())

    def write_edge(transaction):
        transaction.insert(
            "BrainWeaveEdges",
            columns=[
                "edge_id", "owner_id", "source_node_id", "target_node_id",
                "relationship_type", "weight", "confidence", "created_at",
            ],
            values=[[
                edge_id, owner_id, source_id, target_id,
                edge_data.get("relationship_type", "influences"),
                edge_data.get("weight", 1.0),
                1.0,
                spanner.COMMIT_TIMESTAMP,
            ]],
        )

    try:
        database.run_in_transaction(write_edge)
    except Exception as e:
        app.logger.warning(f"Edge creation skipped: {e}")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "brainweave-indexer"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
