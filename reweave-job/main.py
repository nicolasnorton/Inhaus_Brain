"""
BrainWeave Reweave Job — Cloud Run Job
Triggered by Pub/Sub on promotion events.
Runs brainweave_reweave across all connected owners.
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

vertexai.init(project=PROJECT)
spanner_client = spanner.Client(project=PROJECT)
database = spanner_client.instance(INSTANCE).database(DB)
gemini = GenerativeModel(MODEL_ID)


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
