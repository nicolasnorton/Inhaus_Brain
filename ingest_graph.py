import subprocess
import json
import uuid

# Configuration
PROJECT = "inhausbrain"
INSTANCE = "brainweave-graph"
DATABASE = "brainweave"
# The user's specific UID for superadmin/owner visibility
OWNER_ID = "I52W9ogEVuY5ccttEXk4H0ht46B2"

nodes = [
    {
        "node_id": "09a69aee-7930-4e16-97df-bb9216a2da5d",
        "title": "System of Brains",
        "description": "Unified agentic architecture integrating Knowledge Graph, Workspace MCPs, and Metacognition.",
        "content": "A multi-agent system where all participants share a common long-term memory via BrainWeave.",
        "node_type": "architecture",
        "topics": ["system", "orchestration", "memory"],
        "scope": "AGENCY"
    },
    {
        "node_id": "77fb87aa-3618-4b3f-882d-d07d13578fdf",
        "title": "Global Tool Registry",
        "description": "Central nexus for core memory tools and external MCPs.",
        "content": "Exports systemBaselineTools and orchestrationTools to all agents.",
        "node_type": "component",
        "topics": ["tools", "registry", "mcp"],
        "scope": "AGENCY"
    },
    {
        "node_id": "4cbba5da-8969-4398-a1e7-babf8f275dac",
        "title": "Metacognition Layer",
        "description": "Background shared-mind ingestion service.",
        "content": "Listens to AdkEventBus and logs significant agent insights to Spanner.",
        "node_type": "logic",
        "topics": ["metacognition", "memory", "automation"],
        "scope": "AGENCY"
    },
    {
        "node_id": "334da41f-2594-4a4c-8319-1158cc4c21bb",
        "title": "Orchestrator (Brian)",
        "description": "Chief of Staff with full tool access.",
        "content": "The central router and strategist for the System of Brains.",
        "node_type": "agent",
        "topics": ["leadership", "agent", "orchestration"],
        "scope": "AGENCY"
    }
]

edges = [
    ("334da41f-2594-4a4c-8319-1158cc4c21bb", "77fb87aa-3618-4b3f-882d-d07d13578fdf", "uses"),
    ("09a69aee-7930-4e16-97df-bb9216a2da5d", "334da41f-2594-4a4c-8319-1158cc4c21bb", "composed_of"),
    ("09a69aee-7930-4e16-97df-bb9216a2da5d", "4cbba5da-8969-4398-a1e7-babf8f275dac", "composed_of"),
    ("09a69aee-7930-4e16-97df-bb9216a2da5d", "77fb87aa-3618-4b3f-882d-d07d13578fdf", "composed_of"),
    ("4cbba5da-8969-4398-a1e7-babf8f275dac", "77fb87aa-3618-4b3f-882d-d07d13578fdf", "logs_to")
]

def run_sql(sql):
    cmd = [
        "gcloud", "spanner", "databases", "execute-sql", DATABASE,
        f"--instance={INSTANCE}", f"--project={PROJECT}",
        f"--sql={sql}"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error executing SQL: {result.stderr}")
    else:
        print(f"Successfully executed SQL")

print("🧹 Cleaning up old system nodes and edges...")
# Clean up edges first to avoid foreign key violations
for n in nodes:
    sql = f"DELETE FROM BrainWeaveEdges WHERE source_node_id = '{n['node_id']}' OR target_node_id = '{n['node_id']}'"
    run_sql(sql)

# Now delete nodes
for n in nodes:
    sql = f"DELETE FROM BrainWeaveNodes WHERE node_id = '{n['node_id']}'"
    run_sql(sql)

print("🚀 Ingesting System of Brains nodes...")
for n in nodes:
    topics_str = "[" + ",".join([f"'{t}'" for t in n["topics"]]) + "]"
    sql = f"""
    INSERT INTO BrainWeaveNodes (node_id, owner_id, scope, title, description, content, node_type, topics, confidence, created_at, updated_at)
    VALUES ('{n["node_id"]}', '{OWNER_ID}', '{n["scope"]}', '{n["title"]}', '{n["description"]}', '{n["content"]}', '{n["node_type"]}', {topics_str}, 1.0, PENDING_COMMIT_TIMESTAMP(), PENDING_COMMIT_TIMESTAMP())
    """
    run_sql(sql)

print("🚀 Ingesting edges...")
for src, tgt, rel in edges:
    edge_id = str(uuid.uuid4())
    sql = f"""
    INSERT INTO BrainWeaveEdges (edge_id, owner_id, source_node_id, target_node_id, relationship_type, weight, confidence, created_at)
    VALUES ('{edge_id}', '{OWNER_ID}', '{src}', '{tgt}', '{rel}', 1.0, 1.0, PENDING_COMMIT_TIMESTAMP())
    """
    run_sql(sql)

print("✅ Ingestion complete.")
