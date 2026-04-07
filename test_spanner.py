import os
from google.cloud import spanner

PROJECT = "inhausbrain"
INSTANCE = "brainweave-graph"
DB = "brainweave"

client = spanner.Client(project=PROJECT)
instance = client.instance(INSTANCE)
database = instance.database(DB)

try:
    with database.snapshot() as snapshot:
        results = list(snapshot.execute_sql("SELECT COUNT(*) FROM BrainWeaveNodes"))
        print(f"Nodes count: {results[0][0]}")
except Exception as e:
    print(f"Error: {e}")
