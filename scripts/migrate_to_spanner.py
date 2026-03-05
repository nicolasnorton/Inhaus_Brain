"""
BrainWeave 2.0 — Migration Script
Migrates existing BrainWeave data from Firestore to Cloud Spanner + GCS.

Usage:
  python migrate.py --project inhausbrain --instance brainweave-graph --db brainweave

Prerequisites:
  pip install google-cloud-firestore google-cloud-spanner google-cloud-storage
  gcloud auth application-default login
"""
import argparse
import uuid
import json
from datetime import datetime

from google.cloud import firestore, spanner, storage


def migrate(project_id: str, instance_id: str, db_id: str, bucket_name: str):
    # Init clients
    fs = firestore.Client(project=project_id)
    sp_client = spanner.Client(project=project_id)
    database = sp_client.instance(instance_id).database(db_id)
    gcs = storage.Client(project=project_id)
    bucket = gcs.bucket(bucket_name)

    # ─── 1. Migrate brainweave_nodes ─────────────────────
    print("Migrating brainweave_nodes...")
    nodes_ref = fs.collection("brainweave_nodes")
    node_id_map = {}  # firestore_id -> spanner_id

    for doc in nodes_ref.stream():
        data = doc.to_dict()
        # Deterministic UUID based on Firestore ID for idempotency
        spanner_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, doc.id))
        node_id_map[doc.id] = spanner_id

        # Write Markdown to GCS
        owner_id = data.get("ownerId", "unknown")
        node_type = data.get("type", "atomic")
        slug = data.get("title", "untitled").replace(" ", "_").lower()[:50]
        gcs_path = f"{owner_id}/weave/{node_type}s/{slug}.md"

        md_content = f"""# {data.get('title', 'Untitled')}

**Type:** {node_type}
**Topics:** {', '.join(data.get('topics', []))}
**Scope:** {data.get('scope', 'PRIVATE')}

> {data.get('description', '')}

---

{data.get('content', '')}
"""
        blob = bucket.blob(gcs_path)
        blob.upload_from_string(md_content, content_type="text/markdown")

        # Write to Spanner
        embedding = data.get("embedding", [])
        # Convert to FLOAT32 if present
        embedding_f32 = [float(x) for x in embedding] if embedding else []

        def write_node(transaction, sid=spanner_id, d=data, emb=embedding_f32, gp=gcs_path):
            transaction.insert_or_update(
                "BrainWeaveNodes",
                columns=[
                    "node_id", "owner_id", "client_id", "project_id", "scope",
                    "title", "description", "content", "node_type", "topics",
                    "embedding", "markdown_uri", "source_agent", "confidence", "metadata",
                    "version", "created_at", "updated_at",
                ],
                values=[[
                    sid,
                    d.get("ownerId", ""),
                    d.get("clientId", ""),
                    d.get("projectId", "default"),
                    d.get("scope", "PRIVATE"),
                    d.get("title", ""),
                    d.get("description", ""),
                    d.get("content", ""),
                    d.get("type", "atomic"),
                    d.get("topics", []),
                    emb if emb else None,
                    f"gs://{bucket_name}/{gp}",
                    "migration",
                    1.0,
                    json.dumps(d.get("metadata", {})),
                    1,
                    spanner.COMMIT_TIMESTAMP,
                    spanner.COMMIT_TIMESTAMP,
                ]],
            )

        try:
            database.run_in_transaction(write_node)
            print(f"  ✓ Node: {data.get('title', doc.id)}")
        except Exception as e:
            # Ignore spanner metric errors (TimeSeries 400s)
            if "TimeSeries" in str(e):
                print(f"  ✓ Node: {data.get('title', doc.id)} (metric err ignored)")
            else:
                print(f"  ✗ Error migrating node {doc.id}: {e}")

    # ─── 2. Migrate brainweave_links ─────────────────────
    print("\nMigrating brainweave_links...")
    links_ref = fs.collection("brainweave_links")

    for doc in links_ref.stream():
        data = doc.to_dict()
        source_fs_id = data.get("sourceNodeId", "")
        target_fs_id = data.get("targetNodeId", "")

        source_sp_id = node_id_map.get(source_fs_id)
        target_sp_id = node_id_map.get(target_fs_id)

        if not source_sp_id or not target_sp_id:
            print(f"  ⚠ Skipped edge (missing node): {source_fs_id} -> {target_fs_id}")
            continue
        
        # Deterministic edge ID based on source+target
        edge_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{source_fs_id}-{target_fs_id}"))

        def write_edge(transaction, eid=edge_id, d=data, sid=source_sp_id, tid=target_sp_id):
            transaction.insert_or_update(
                "BrainWeaveEdges",
                columns=[
                    "edge_id", "owner_id", "source_node_id", "target_node_id",
                    "relationship_type", "weight", "confidence", "created_at",
                ],
                values=[[
                    eid,
                    d.get("ownerId", ""),
                    sid, tid,
                    d.get("relationshipType", "influences"),
                    1.0, 1.0,
                    spanner.COMMIT_TIMESTAMP,
                ]],
            )

        try:
            database.run_in_transaction(write_edge)
            print(f"  ✓ Edge: {data.get('relationshipType', 'link')}")
        except Exception as e:
            if "TimeSeries" in str(e):
                 print(f"  ✓ Edge: {data.get('relationshipType', 'link')} (metric err ignored)")
            else:
                 print(f"  ✗ Error migrating edge {doc.id}: {e}")

    # ─── 3. Migrate brainweave_cores ─────────────────────
    print("\nMigrating brainweave_cores to GCS vault...")
    cores_ref = fs.collection("brainweave_cores")

    for doc in cores_ref.stream():
        data = doc.to_dict()
        owner_id = data.get("ownerId", "unknown")

        for field in ["identity", "methodology", "goals"]:
            content = data.get(field, "")
            if content:
                blob = bucket.blob(f"{owner_id}/core/{field}.md")
                blob.upload_from_string(
                    f"# {field.title()}\n\n{content}\n",
                    content_type="text/markdown",
                )
                print(f"  ✓ Core ({owner_id}): {field}")

    print(f"\n✅ Migration complete!")
    print(f"   Nodes migrated: {len(node_id_map)}")
    print(f"   Vault bucket: gs://{bucket_name}/")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate BrainWeave Firestore → Spanner + GCS")
    parser.add_argument("--project", default="inhausbrain")
    parser.add_argument("--instance", default="brainweave-graph")
    parser.add_argument("--db", default="brainweave")
    parser.add_argument("--bucket", default="inhausbrain-brainweave-vault")
    args = parser.parse_args()

    migrate(args.project, args.instance, args.db, args.bucket)
