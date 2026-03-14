import os
import json
import logging
import uuid
from google.cloud import spanner
import vertexai
from vertexai.generative_models import GenerativeModel

PROJECT = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB = os.environ.get("SPANNER_DB", "brainweave")
MODEL_ID = os.environ.get("GEMINI_MODEL", "gemini-3.1-pro")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def detect_contradictions(owner_id: str):
    """Run contradiction detection for a specific owner. Requires owner_id to prevent cross-tenant access."""
    if not owner_id:
        raise ValueError("owner_id is required to scope contradiction detection")

    vertexai.init(project=PROJECT)
    spanner_client = spanner.Client(project=PROJECT)
    database = spanner_client.instance(INSTANCE).database(DB)
    gemini = GenerativeModel(MODEL_ID)

    logger.info(f"Starting BrainWeave Contradiction Detection Job for owner {owner_id}")

    # Fetch edges for a specific owner only (prevents cross-tenant data leakage)
    sql = """
        SELECT e.edge_id, n1.node_id, n1.title, n1.content, n2.node_id, n2.title, n2.content
        FROM BrainWeaveEdges e
        JOIN BrainWeaveNodes n1 ON e.source_node_id = n1.node_id
        JOIN BrainWeaveNodes n2 ON e.target_node_id = n2.node_id
        WHERE n1.owner_id = @owner_id AND n2.owner_id = @owner_id
        LIMIT 100
    """

    with database.snapshot() as snapshot:
        rows = list(snapshot.execute_sql(
            sql,
            params={"owner_id": owner_id},
            param_types={"owner_id": spanner.param_types.STRING}
        ))

    for row in rows:
        edge_id, id1, t1, c1, id2, t2, c2 = row
        
        prompt = f"""Compare these two knowledge nodes and identify if they contradict each other.
        Node A: {t1} - {c1[:1000]}
        Node B: {t2} - {c2[:1000]}
        
        If they contradict, explain why. If they don't, respond with 'CONSISTENT'.
        """
        
        response = gemini.generate_content(prompt)
        analysis = response.text.strip()
        
        if "CONSISTENT" not in analysis:
            logger.info(f"Contradiction detected between {t1} and {t2}")
            
            # Create a 'contradiction' edge or update existing
            def update_graph(transaction):
                # Update existing edge to 'contradicts' type
                transaction.execute_update(
                    "UPDATE BrainWeaveEdges SET relationship_type = 'contradicts', confidence = 0.9 "
                    "WHERE edge_id = @eid",
                    params={"eid": edge_id},
                    param_types={"eid": spanner.param_types.STRING}
                )
                
                # Add annotation to node 1
                transaction.insert(
                    "BrainWeaveAnnotations",
                    columns=["annotation_id", "node_id", "owner_id", "text", "provenance", "created_at"],
                    values=[[str(uuid.uuid4()), id1, "system", f"Contradiction found with '{t2}': {analysis[:500]}", "Contradiction Detector", spanner.COMMIT_TIMESTAMP]]
                )

            database.run_in_transaction(update_graph)

    logger.info("Contradiction detection complete")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python contradiction_detector.py <owner_id>")
        sys.exit(1)
    detect_contradictions(owner_id=sys.argv[1])
