"""
BrainWeave Reweave Job — Cloud Run Job (BW3.0 Evolution)
Triggered by Pub/Sub on promotion events.
Runs brainweave_reweave across all connected owners.
BW3.0: Adds self-healing contradiction detection phase.
"""
import json
import os
import sys

from google.cloud import spanner
import vertexai
from vertexai.generative_models import GenerativeModel

PROJECT  = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB       = os.environ.get("SPANNER_DB", "brainweave")
MODEL_ID = os.environ.get("GEMINI_MODEL", "gemini-3.1-pro")
BW30_ENABLED = os.environ.get("BRAINWEAVE_3_0_EVOLUTION_ENABLED", "false").lower() == "true"

vertexai.init(project=PROJECT)
spanner_client = spanner.Client(project=PROJECT)
database = spanner_client.instance(INSTANCE).database(DB)
gemini = GenerativeModel(MODEL_ID)


def self_heal_check(node_id: str, source_title: str, source_content: str, neighbors: list):
    """BW3.0: Check for contradictions between source and neighbors before reweaving."""
    if not neighbors or len(neighbors) < 2:
        return 0

    node_summaries = "\n".join(
        f"- [{nid[:8]}] {ntitle}: {ndesc[:100]}" for nid, ntitle, ndesc in neighbors
    )

    prompt = (
        f"Source node '{source_title}': {source_content[:300]}\n\n"
        f"Connected nodes:\n{node_summaries}\n\n"
        f"Are there any contradictions between these nodes? "
        f"Reply with JSON: {{\"contradictions\": [{{\"node_id\": \"...\", "
        f"\"description\": \"...\", \"fixed_description\": \"...\"}}]}} "
        f"or {{\"contradictions\": []}} if none found."
    )

    try:
        response = gemini.generate_content(prompt)
        text = response.text.strip()
        if text.startswith("```json"): text = text[7:]
        if text.endswith("```"): text = text[:-3]
        result = json.loads(text)

        fixes = 0
        for c in result.get("contradictions", []):
            fix_id = c.get("node_id")
            fix_desc = c.get("fixed_description")
            if fix_id and fix_desc:
                def fix_txn(transaction, nid=fix_id, desc=fix_desc[:2048]):
                    transaction.update(
                        "BrainWeaveNodes",
                        columns=["node_id", "description", "updated_at"],
                        values=[[nid, desc, spanner.COMMIT_TIMESTAMP]],
                    )
                try:
                    database.run_in_transaction(fix_txn)
                    fixes += 1
                    print(f"  Self-heal fix applied to {fix_id}")
                except Exception as e:
                    print(f"  Self-heal fix failed for {fix_id}: {e}")
        return fixes
    except Exception as e:
        print(f"  Self-heal check error (non-fatal): {e}")
        return 0


def reweave_node(node_id: str):
    """Run backward-update reweave on a promoted node and its neighbors."""
    # Get source node
    with database.snapshot() as snapshot:
        source = list(snapshot.execute_sql(
            "SELECT title, content FROM BrainWeaveNodes WHERE node_id = @nid",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    if not source:
        print(f"Node {node_id} not found, skipping.")
        return

    source_title, source_content = source[0]

    # Get connected neighbors (across all owners for agency-level reweave)
    with database.snapshot() as snapshot:
        neighbors = list(snapshot.execute_sql(
            "SELECT n.node_id, n.title, n.description "
            "FROM BrainWeaveEdges e JOIN BrainWeaveNodes n "
            "ON (e.target_node_id = n.node_id OR e.source_node_id = n.node_id) "
            "WHERE (e.source_node_id = @nid OR e.target_node_id = @nid) "
            "AND n.node_id != @nid",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    # BW3.0: Self-healing contradiction detection phase
    if BW30_ENABLED and neighbors:
        print(f"  BW3.0: Running self-heal check across {len(neighbors)} neighbors...")
        heal_fixes = self_heal_check(node_id, source_title, source_content, neighbors)
        print(f"  BW3.0: Self-heal applied {heal_fixes} fixes.")

    updated_count = 0
    for nid, ntitle, ndesc in neighbors:
        prompt = (
            f"Node '{source_title}' has been promoted to agency-wide visibility with content:\n"
            f"{source_content[:500]}\n\n"
            f"Connected node '{ntitle}' currently says: {ndesc}\n\n"
            f"Should the connected node's description be updated to reflect "
            f"the new agency-level knowledge? If yes, provide the updated description. "
            f"If no, respond with 'NO_CHANGE'."
        )
        response = gemini.generate_content(prompt)
        suggestion = response.text.strip()

        if suggestion and "NO_CHANGE" not in suggestion:
            def update_txn(transaction, target_id=nid, new_desc=suggestion[:2048]):
                transaction.update(
                    "BrainWeaveNodes",
                    columns=["node_id", "description", "updated_at"],
                    values=[[target_id, new_desc, spanner.COMMIT_TIMESTAMP]],
                )
            database.run_in_transaction(update_txn)
            updated_count += 1
            print(f"  Updated neighbor: {ntitle}")

    print(f"Reweave complete for {node_id}: {updated_count}/{len(neighbors)} neighbors updated.")


def main():
    """Entry point — reads Pub/Sub message from CLOUD_RUN_TASK env or stdin."""
    # Cloud Run Jobs receive data via environment or arguments
    message_data = os.environ.get("PUBSUB_MESSAGE")
    if not message_data and len(sys.argv) > 1:
        message_data = sys.argv[1]

    if not message_data:
        print("No message data provided. Exiting.")
        return

    try:
        payload = json.loads(message_data)
        node_id = payload.get("node_id")
        if node_id:
            print(f"Starting reweave for promoted node: {node_id}")
            reweave_node(node_id)
        else:
            print("No node_id in message payload.")
    except json.JSONDecodeError as e:
        print(f"Invalid JSON message: {e}")


if __name__ == "__main__":
    main()

