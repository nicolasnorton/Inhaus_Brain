"""
BrainWeave Context-Hub Jobs
Cloud Functions (Python) for background analysis in the Context-Hub.
"""

import os
import json
import uuid
import functions_framework
from google.cloud import spanner
import vertexai
from vertexai.generative_models import GenerativeModel

PROJECT = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB = os.environ.get("SPANNER_DB", "brainweave")
MODEL_ID = os.environ.get("GEMINI_MODEL", "gemini-3.1-pro")

vertexai.init(project=PROJECT)
spanner_client = spanner.Client(project=PROJECT)
database = spanner_client.instance(INSTANCE).database(DB)
gemini = GenerativeModel(MODEL_ID)

@functions_framework.cloud_event
def nightly_gap_analysis(cloud_event):
    """
    Reviews highly downvoted nodes or annotations to extract knowledge gaps.
    Triggered daily by Cloud Scheduler pub/sub.
    """
    print("Starting Nightly Gap Analysis...")

    with database.snapshot() as snapshot:
        # Get target_ids with net negative votes
        feedbacks = list(snapshot.execute_sql(
            "SELECT target_id, SUM(vote) as net_score "
            "FROM BrainWeaveFeedbacks "
            "GROUP BY target_id HAVING SUM(vote) < 0"
        ))

    if not feedbacks:
        print("No negative feedback found. Graph is healthy.")
        return

    gap_count = 0
    for target_id, score in feedbacks:
        with database.snapshot() as snapshot:
            nodes = list(snapshot.execute_sql(
                "SELECT title, content FROM BrainWeaveNodes WHERE node_id = @tid",
                params={"tid": target_id},
                param_types={"tid": spanner.param_types.STRING}
            ))
            if not nodes:
                continue
            
            title, content = nodes[0]
            prompt = (
                f"The following knowledge node (Title: {title}) has received negative feedback "
                f"from agents and users. Identify the most likely knowledge gap or error:\\n\\n{content[:2000]}"
            )
            response = gemini.generate_content(prompt)
            print(f"Gap Identified for {title}: {response.text.strip()}")
            gap_count += 1

    print(f"Completed gap analysis for {gap_count} nodes.")

@functions_framework.cloud_event
def contradiction_detector(cloud_event):
    """
    Scans recent nodes for contradictions using Vertex AI.
    Triggered periodically.
    """
    print("Starting Contradiction Detector...")
    
    with database.snapshot() as snapshot:
        # Get latest nodes
        recent_nodes = list(snapshot.execute_sql(
            "SELECT node_id, title, description, content, owner_id "
            "FROM BrainWeaveNodes "
            "ORDER BY created_at DESC LIMIT 50"
        ))

    if len(recent_nodes) < 2:
        return

    # Check for contradictions among the batch
    context = ""
    for r in recent_nodes:
        context += f"Node [{r[1]} - {r[0]}]: {r[2]}\\n"

    prompt = (
        "You are the BrainWeave Context-Hub CEO Agent's Contradiction Detector.\\n"
        "Analyze the following recent knowledge nodes for explicit contradictions.\\n"
        "If you find a contradiction, respond with the two node IDs and describe the conflict.\\n"
        "If there are no contradictions, respond with 'NO_CONTRADICTIONS'.\\n\\n"
        f"{context}"
    )

    response = gemini.generate_content(prompt)
    if "NO_CONTRADICTIONS" not in response.text:
        print(f"CONTRADICTION DETECTED:\\n{response.text.strip()}")
        # Future CEO-Agent behavior will consume this output via Pub/Sub to trigger refactors
    else:
        print("No contradictions detected in recent nodes.")
