import os
from google.cloud import spanner

PROJECT = "inhausbrain"
INSTANCE = "brainweave-graph"
DB = "brainweave"

client = spanner.Client(project=PROJECT)
database = client.instance(INSTANCE).database(DB)

def test_query():
    try:
        owner_id = 'I52W9ogEVuY5ccttEXk4H0ht46B2'
        sql = "SELECT node_id, title FROM BrainWeaveNodes WHERE owner_id = @oid LIMIT 1"
        params = {'oid': owner_id}
        param_types = {'oid': spanner.param_types.STRING}
        
        with database.snapshot() as snapshot:
            results = list(snapshot.execute_sql(sql, params=params, param_types=param_types))
            print(f"Results: {results}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_query()
