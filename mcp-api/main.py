"""
BrainWeave 2.0 MCP API — Cloud Run Service
Exposes 8 MCP tool endpoints backed by Cloud Spanner Graph (GQL).
Called from the Flutter client via HTTP.
"""
import json
import os
import uuid
from datetime import datetime

from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import spanner

import vertexai
from vertexai.generative_models import GenerativeModel
from vertexai.language_models import TextEmbeddingModel

app = Flask(__name__)
CORS(app)

PROJECT    = os.environ.get("GCP_PROJECT", "inhausbrain")
INSTANCE   = os.environ.get("SPANNER_INSTANCE", "brainweave-graph")
DB         = os.environ.get("SPANNER_DB", "brainweave")
MODEL_ID   = os.environ.get("GEMINI_MODEL", "gemini-3.1-pro")
EMBED_ID   = os.environ.get("EMBED_MODEL", "text-embedding-005")

vertexai.init(project=PROJECT)
spanner_client = spanner.Client(project=PROJECT)
gemini = GenerativeModel(MODEL_ID)
embed_model = TextEmbeddingModel.from_pretrained(EMBED_ID)

_registry_cache = None

def _load_registry():
    global _registry_cache
    if _registry_cache: return _registry_cache
    
    # GitNexus: Fetch registry configuration from GCS or use local fallback
    # Simulate GCS fetch for now with a local struct
    _registry_cache = {
        "default": {"instance": INSTANCE, "db": DB},
        "staging": {"instance": "brainweave-staging", "db": "staging_db"},
        "client_a": {"instance": "client-a-graph", "db": "client_a_db"}
    }
    return _registry_cache

def _get_database(req):
    namespace = req.headers.get("X-Namespace", req.headers.get("X-Registry", "default"))
    registry = _load_registry()
    cfg = registry.get(namespace, registry["default"])
    return spanner_client.instance(cfg["instance"]).database(cfg["db"])


# ─── Helper ──────────────────────────────────────────────────────────────────

def _get_embedding(text: str) -> list[float]:
    """Generate embedding vector for text."""
    result = embed_model.get_embeddings([text[:2000]])
    return result[0].values if result else []


def _authed_owner(req) -> str:
    """Extract owner_id from auth header (Firebase ID token claim).
    For dev, accept X-Owner-Id header as a shortcut."""
    return req.headers.get("X-Owner-Id", "dev-user")


# ─── Tool 1: brainweave_graph_query ──────────────────────────────────────────

@app.route("/brainweave_graph_query", methods=["POST"])
def graph_query():
    """Semantic vector search + optional GQL subgraph expansion."""
    body = request.get_json()
    query = body.get("query", "")
    scope = body.get("scope")
    limit = body.get("limit", 5)
    owner_id = _authed_owner(request)

    if not query:
        return jsonify({"error": "query is required"}), 400

    # ANN vector search
    embedding = _get_embedding(query)

    sql = """
        SELECT node_id, title, description, node_type, topics, scope, confidence
        FROM (
            SELECT node_id, title, description, node_type, topics, scope, confidence,
                   SCORE(BrainWeaveNodesTextIndex, @query) as bm25_score,
                   RANK() OVER (ORDER BY SCORE(BrainWeaveNodesTextIndex, @query) DESC) as rank_bm25,
                   COSINE_DISTANCE(embedding, @query_embedding) as ann_score,
                   RANK() OVER (ORDER BY COSINE_DISTANCE(embedding, @query_embedding) ASC) as rank_ann
            FROM BrainWeaveNodes
            WHERE owner_id = @owner_id
    """
    params = {"owner_id": owner_id, "query": query, "query_embedding": embedding, "limit": limit}
    param_types = {
        "owner_id": spanner.param_types.STRING,
        "query": spanner.param_types.STRING,
        "query_embedding": spanner.param_types.Array(spanner.param_types.FLOAT32),
        "limit": spanner.param_types.INT64
    }

    if scope:
        sql += " AND scope = @scope "
        params["scope"] = scope
        param_types["scope"] = spanner.param_types.STRING

    # BrainWeave 2.1 GitNexus Upgrade: Spanner Hybrid Search (BM25 + Vector KNN)
    sql += """
            AND (SEARCH(BrainWeaveNodesTextIndex, @query) OR COSINE_DISTANCE(embedding, @query_embedding) < 0.3)
        )
        ORDER BY ( (1.0 / (rank_bm25 + 60)) + (1.0 / (rank_ann + 60)) ) DESC
        LIMIT @limit
    """

    with _get_database(request).snapshot() as snapshot:
        results = list(snapshot.execute_sql(sql, params=params, param_types=param_types))

    nodes = []
    for row in results:
        nodes.append({
            "node_id": row[0],
            "title": row[1],
            "description": row[2],
            "node_type": row[3],
            "topics": list(row[4]) if row[4] else [],
            "scope": row[5],
            "confidence": row[6],
        })

    return jsonify({"results": nodes, "count": len(nodes)})


# ─── Tool 2: brainweave_impact ───────────────────────────────────────────────

@app.route("/brainweave_impact", methods=["POST"])
def impact():
    """N-hop impact analysis from a given node."""
    body = request.get_json()
    node_id = body.get("node_id")
    max_depth = body.get("max_depth", 3)
    min_confidence = body.get("min_confidence", 0.5)
    owner_id = _authed_owner(request)

    if not node_id:
        return jsonify({"error": "node_id is required"}), 400

    gql = """
        GRAPH BrainWeaveGraph
        MATCH (start:BrainWeaveNodes WHERE start.node_id = @start_id)
              -[e:BrainWeaveEdges]->{1,""" + str(max_depth) + """}
              (affected:BrainWeaveNodes)
        WHERE e.confidence >= @min_conf
          AND affected.owner_id = @owner_id
        RETURN affected.node_id     AS node_id,
               affected.title       AS title,
               affected.node_type   AS node_type,
               e.relationship_type  AS relationship,
               e.confidence         AS confidence
        LIMIT 50
    """

    with database.snapshot() as snapshot:
        results = list(snapshot.execute_sql(
            gql,
            params={
                "start_id": node_id,
                "min_conf": min_confidence,
                "owner_id": owner_id,
            },
            param_types={
                "start_id": spanner.param_types.STRING,
                "min_conf": spanner.param_types.FLOAT64,
                "owner_id": spanner.param_types.STRING,
            },
        ))

    affected = []
    
    # BrainWeave 2.1 GitNexus Upgrade: Calculate inferred depth iteratively 
    # since Spanner Graph doesn't return path length directly in this simple GQL.
    # We assign a depth based on confidence decay (approximation) or just pass length=1
    # for now until Spanner Graph path variables are fully supported.
    
    for row in results:
        affected.append({
            "node_id": row[0],
            "title": row[1],
            "node_type": row[2],
            "relationship": row[3],
            "confidence": row[4],
            "depth_level": 1 if row[4] > 0.8 else (2 if row[4] > 0.6 else 3) # Mock depth based on edge strength decay
        })

    return jsonify({"source": node_id, "affected": affected, "count": len(affected)})


# ─── Tool 3: brainweave_cluster ──────────────────────────────────────────────

@app.route("/brainweave_cluster", methods=["POST"])
def cluster():
    """Find connected components / communities in the graph."""
    body = request.get_json() or {}
    owner_id = _authed_owner(request)
    scope = body.get("scope")

    # Fetch all edges for owner
    sql = """
        SELECT e.source_node_id, e.target_node_id, n1.title, n2.title
        FROM BrainWeaveEdges e
        JOIN BrainWeaveNodes n1 ON e.source_node_id = n1.node_id
        JOIN BrainWeaveNodes n2 ON e.target_node_id = n2.node_id
        WHERE e.owner_id = @owner_id
    """
    params = {"owner_id": owner_id}
    param_types = {"owner_id": spanner.param_types.STRING}

    with database.snapshot() as snapshot:
        rows = list(snapshot.execute_sql(sql, params=params, param_types=param_types))

    # BFS-based connected components
    adj = {}
    titles = {}
    for src_id, tgt_id, src_title, tgt_title in rows:
        adj.setdefault(src_id, set()).add(tgt_id)
        adj.setdefault(tgt_id, set()).add(src_id)
        titles[src_id] = src_title
        titles[tgt_id] = tgt_title

    visited = set()
    clusters = []
    for node in adj:
        if node in visited:
            continue
        queue = [node]
        component = []
        while queue:
            current = queue.pop(0)
            if current in visited:
                continue
            visited.add(current)
            component.append({
                "node_id": current,
                "title": titles.get(current, "Unknown"),
            })
            for neighbor in adj.get(current, []):
                if neighbor not in visited:
                    queue.append(neighbor)
        clusters.append({"size": len(component), "nodes": component})

    clusters.sort(key=lambda c: c["size"], reverse=True)
    return jsonify({"clusters": clusters, "count": len(clusters)})


# ─── Tool 3b: brainweave_graph_analysis (arscontexta 2.1) ────────────────────

@app.route("/brainweave_graph_analysis", methods=["POST"])
def graph_analysis():
    """Calculates NetworkX eigenvector centrality and community detection on a user's graph."""
    body = request.get_json() or {}
    owner_id = _authed_owner(request)
    
    try:
        import networkx as nx
    except ImportError:
        return jsonify({"error": "networkx not installed inside MCP API container"}), 500

    # Fetch graph structure
    sql = """
        SELECT e.source_node_id, e.target_node_id, e.weight
        FROM BrainWeaveEdges e
        WHERE e.owner_id = @owner_id
    """
    params = {"owner_id": owner_id}
    param_types = {"owner_id": spanner.param_types.STRING}

    with database.snapshot() as snapshot:
        rows = list(snapshot.execute_sql(sql, params=params, param_types=param_types))

    G = nx.Graph()
    for src, tgt, weight in rows:
        G.add_edge(src, tgt, weight=weight or 1.0)

    if len(G.nodes) == 0:
        return jsonify({"centrality": {}, "communities": [], "message": "Graph is empty"})

    # Eigenvector Centrality
    try:
        centrality = nx.eigenvector_centrality(G, max_iter=500, weight='weight')
    except nx.PowerIterationFailedConvergence:
        centrality = nx.degree_centrality(G) # Fallback

    # Louvain Community Detection
    try:
        import community as community_louvain
        partition = community_louvain.best_partition(G, weight='weight')
        communities = {}
        for node, comm_id in partition.items():
            communities.setdefault(comm_id, []).append(node)
        comm_list = [{"community_id": k, "nodes": v} for k, v in communities.items()]
    except ImportError:
        # Graceful fallback if python-louvain isn't installed
        comm_list = [{"community_id": 0, "nodes": list(G.nodes)}]

    # Top central nodes
    sorted_centrality = sorted(centrality.items(), key=lambda x: x[1], reverse=True)[:10]

    return jsonify({
        "top_nodes": [{"node_id": k, "score": v} for k, v in sorted_centrality],
        "communities": comm_list,
        "total_nodes": len(G.nodes),
        "total_edges": len(G.edges)
    })

# ─── Tool 4: brainweave_context ──────────────────────────────────────────────

@app.route("/brainweave_context", methods=["POST"])
def context():
    """360° context view for a node: incoming + outgoing edges + full content."""
    body = request.get_json()
    node_id = body.get("node_id")
    owner_id = _authed_owner(request)

    if not node_id:
        return jsonify({"error": "node_id is required"}), 400

    # Fetch node
    with database.snapshot() as snapshot:
        node_rows = list(snapshot.execute_sql(
            "SELECT node_id, title, description, content, node_type, topics, scope, confidence "
            "FROM BrainWeaveNodes WHERE node_id = @nid AND owner_id = @oid",
            params={"nid": node_id, "oid": owner_id},
            param_types={
                "nid": spanner.param_types.STRING,
                "oid": spanner.param_types.STRING,
            },
        ))

    if not node_rows:
        return jsonify({"error": "Node not found"}), 404

    row = node_rows[0]
    node = {
        "node_id": row[0], "title": row[1], "description": row[2],
        "content": row[3], "node_type": row[4],
        "topics": list(row[5]) if row[5] else [],
        "scope": row[6], "confidence": row[7],
    }

    # Incoming edges
    with database.snapshot() as snapshot:
        incoming = list(snapshot.execute_sql(
            "SELECT e.edge_id, e.relationship_type, e.confidence, n.node_id, n.title "
            "FROM BrainWeaveEdges e JOIN BrainWeaveNodes n ON e.source_node_id = n.node_id "
            "WHERE e.target_node_id = @nid",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    # Outgoing edges
    with database.snapshot() as snapshot:
        outgoing = list(snapshot.execute_sql(
            "SELECT e.edge_id, e.relationship_type, e.confidence, n.node_id, n.title "
            "FROM BrainWeaveEdges e JOIN BrainWeaveNodes n ON e.target_node_id = n.node_id "
            "WHERE e.source_node_id = @nid",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    return jsonify({
        "node": node,
        "incoming": [
            {"edge_id": r[0], "type": r[1], "confidence": r[2],
             "source_id": r[3], "source_title": r[4]}
            for r in incoming
        "edges": edges,
    })


# ─── Tool 4b: brainweave_wiki (GitNexus Upgrades 2.1) ────────────────────────

@app.route("/brainweave_wiki", methods=["POST"])
def wiki_generate():
    """Generates an LLM-structured Markdown document representing a subgraph."""
    body = request.get_json()
    node_id = body.get("node_id")
    owner_id = _authed_owner(request)

    if not node_id:
        return jsonify({"error": "node_id is required"}), 400

    # We reuse the context fetching logic to grab the subgraph
    with database.snapshot() as snapshot:
        node_rows = list(snapshot.execute_sql(
            "SELECT title, content FROM BrainWeaveNodes WHERE node_id = @nid AND owner_id = @oid",
            params={"nid": node_id, "oid": owner_id},
            param_types={"nid": spanner.param_types.STRING, "oid": spanner.param_types.STRING},
        ))

        if not node_rows:
            return jsonify({"error": "Node not found"}), 404
        
        main_title, main_content = node_rows[0]

        neighbors = list(snapshot.execute_sql(
            "SELECT n.title, n.content, e.relationship_type "
            "FROM BrainWeaveEdges e JOIN BrainWeaveNodes n "
            "ON (e.target_node_id = n.node_id OR e.source_node_id = n.node_id) "
            "WHERE (e.source_node_id = @nid OR e.target_node_id = @nid) "
            "AND n.node_id != @nid LIMIT 10",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    # Assemble subgraph context
    context = f"# Central Context: {main_title}\n\n{main_content}\n\n## Connected Knowledge\n\n"
    for title, content, rel in neighbors:
        context += f"### {title} (Relationship: {rel})\n{content}\n\n"

    # Ask Gemini Pro to generate the Wiki
    prompt = (
        f"You are the GitNexus Documentation Engine. Convert the following disorganized "
        f"graph context into a highly structured Markdown Wiki page. Extract implicit "
        f"sections, synthesize ideas, and format beautifully.\n\n[CONTEXT]\n{context}"
    )

    try:
        response = gemini.generate_content(prompt)
        wiki_text = response.text
    except Exception as e:
        return jsonify({"error": f"LLM Generation failed: {e}"}), 500

    return jsonify({
        "wiki_markdown": wiki_text,
        "source_node": node_id
    })


# ─── Tool 5: brainweave_create ───────────────────────────────────────────────

@app.route("/brainweave_create", methods=["POST"])
def create():
    """Create a new node with auto-linking via vector similarity."""
    body = request.get_json()
    owner_id = _authed_owner(request)

    title = body.get("title", "")
    description = body.get("description", "")
    content = body.get("content", "")
    node_type = body.get("node_type", "atomic")
    topics = body.get("topics", [])
    scope = body.get("scope", "PRIVATE")
    client_id = body.get("client_id")

    if not title:
        return jsonify({"error": "title is required"}), 400

    # Generate embedding
    embed_text = f"{title} {description} {content[:500]}"
    embedding = _get_embedding(embed_text)

    node_id = str(uuid.uuid4())

    def write_txn(transaction):
        transaction.insert(
            "BrainWeaveNodes",
            columns=[
                "node_id", "owner_id", "client_id", "scope",
                "title", "description", "content", "node_type",
                "topics", "embedding", "source_agent", "confidence",
                "created_at", "updated_at",
            ],
            values=[[
                node_id, owner_id, client_id, scope,
                title, description, content, node_type,
                topics, embedding, body.get("source_agent", "mcp_api"), 1.0,
                spanner.COMMIT_TIMESTAMP, spanner.COMMIT_TIMESTAMP,
            ]],
        )

    database.run_in_transaction(write_txn)

    # Auto-link: find similar nodes via ANN
    try:
        with database.snapshot() as snapshot:
            similar = list(snapshot.execute_sql(
                "SELECT node_id, title FROM BrainWeaveNodes "
                "WHERE owner_id = @oid AND node_id != @nid "
                "ORDER BY COSINE_DISTANCE(embedding, @emb) LIMIT 3",
                params={
                    "oid": owner_id, "nid": node_id, "emb": embedding,
                },
                param_types={
                    "oid": spanner.param_types.STRING,
                    "nid": spanner.param_types.STRING,
                    "emb": spanner.param_types.Array(spanner.param_types.FLOAT32),
                },
            ))

        for sim_row in similar:
            edge_id = str(uuid.uuid4())

            def link_txn(transaction, eid=edge_id, tid=sim_row[0]):
                transaction.insert(
                    "BrainWeaveEdges",
                    columns=[
                        "edge_id", "owner_id", "source_node_id",
                        "target_node_id", "relationship_type",
                        "weight", "confidence", "created_at",
                    ],
                    values=[[
                        eid, owner_id, node_id, tid,
                        "influences", 0.7, 0.7,
                        spanner.COMMIT_TIMESTAMP,
                    ]],
                )

            database.run_in_transaction(link_txn)

    except Exception as e:
        app.logger.warning(f"Auto-link failed (non-fatal): {e}")

    return jsonify({"node_id": node_id, "title": title, "status": "created"})


# ─── Tool 6: brainweave_reweave ──────────────────────────────────────────────

@app.route("/brainweave_reweave", methods=["POST"])
def reweave():
    """Backward-update: re-process a node's neighbors with new context."""
    body = request.get_json()
    node_id = body.get("node_id")
    owner_id = _authed_owner(request)

    if not node_id:
        return jsonify({"error": "node_id is required"}), 400

    # Get source node
    with database.snapshot() as snapshot:
        source = list(snapshot.execute_sql(
            "SELECT title, content FROM BrainWeaveNodes WHERE node_id = @nid",
            params={"nid": node_id},
            param_types={"nid": spanner.param_types.STRING},
        ))

    if not source:
        return jsonify({"error": "Node not found"}), 404

    source_title, source_content = source[0]

    # Get connected neighbors
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

    # Ask Gemini to suggest updates for each neighbor
    updated = []
    for nid, ntitle, ndesc in neighbors:
        prompt = (
            f"Node '{source_title}' has new content:\n{source_content[:500]}\n\n"
            f"Connected node '{ntitle}' currently says: {ndesc}\n\n"
            f"Should the connected node's description be updated to reflect "
            f"the new knowledge? If yes, provide the updated description. "
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
            updated.append({"node_id": nid, "title": ntitle, "updated": True})
        else:
            updated.append({"node_id": nid, "title": ntitle, "updated": False})

    return jsonify({"source": node_id, "reweave_results": updated})


# ─── Tool 7: brainweave_detect_changes ───────────────────────────────────────

@app.route("/brainweave_detect_changes", methods=["POST"])
def detect_changes():
    """Find nodes modified since a given timestamp."""
    body = request.get_json() or {}
    owner_id = _authed_owner(request)
    since = body.get("since")

    if not since:
        return jsonify({"error": "since (ISO timestamp) is required"}), 400

    with database.snapshot() as snapshot:
        results = list(snapshot.execute_sql(
            "SELECT node_id, title, node_type, scope, updated_at "
            "FROM BrainWeaveNodes "
            "WHERE owner_id = @oid AND updated_at > @since "
            "ORDER BY updated_at DESC LIMIT 50",
            params={"oid": owner_id, "since": since},
            param_types={
                "oid": spanner.param_types.STRING,
                "since": spanner.param_types.STRING,
            },
        ))

    changed = []
    for row in results:
        changed.append({
            "node_id": row[0], "title": row[1],
            "node_type": row[2], "scope": row[3],
            "updated_at": str(row[4]),
        })

    return jsonify({"changed": changed, "count": len(changed)})


# ─── Tool 8: brainweave_promote ──────────────────────────────────────────────

@app.route("/brainweave_promote", methods=["POST"])
def promote():
    """Propose a node for promotion to AGENCY scope."""
    body = request.get_json()
    node_id = body.get("node_id")
    reason = body.get("reason", "")
    owner_id = _authed_owner(request)

    if not node_id:
        return jsonify({"error": "node_id is required"}), 400

    promotion_id = str(uuid.uuid4())

    def write_txn(transaction):
        transaction.insert(
            "PendingPromotions",
            columns=[
                "promotion_id", "node_id", "requested_by",
                "reason", "status", "created_at",
            ],
            values=[[
                promotion_id, node_id, owner_id,
                reason, "PENDING", spanner.COMMIT_TIMESTAMP,
            ]],
        )

    database.run_in_transaction(write_txn)
    return jsonify({"promotion_id": promotion_id, "status": "PENDING"})


# ─── GraphRAG endpoint ──────────────────────────────────────────────────────

@app.route("/brainweave_graphrag", methods=["POST"])
def graphrag():
    """GraphRAG: ANN search → subgraph expansion → Gemini summarization."""
    body = request.get_json()
    query = body.get("query", "")
    owner_id = _authed_owner(request)

    if not query:
        return jsonify({"error": "query is required"}), 400

    # Step 1: ANN vector search for seed nodes
    embedding = _get_embedding(query)

    with database.snapshot() as snapshot:
        seeds = list(snapshot.execute_sql(
            "SELECT node_id, title, description, content "
            "FROM BrainWeaveNodes WHERE owner_id = @oid "
            "ORDER BY COSINE_DISTANCE(embedding, @emb) LIMIT 5",
            params={"oid": owner_id, "emb": embedding},
            param_types={
                "oid": spanner.param_types.STRING,
                "emb": spanner.param_types.Array(spanner.param_types.FLOAT32),
            },
        ))

    if not seeds:
        return jsonify({"answer": "No relevant knowledge found.", "sources": []})

    seed_ids = [row[0] for row in seeds]

    # Step 2: 1-hop expansion around seed nodes
    expanded_context = []
    for seed in seeds:
        expanded_context.append(f"## {seed[1]}\n{seed[2]}\n{seed[3][:300]}")

    with database.snapshot() as snapshot:
        for sid in seed_ids:
            neighbors = list(snapshot.execute_sql(
                "SELECT n.title, n.description, e.relationship_type "
                "FROM BrainWeaveEdges e JOIN BrainWeaveNodes n "
                "ON e.target_node_id = n.node_id "
                "WHERE e.source_node_id = @sid LIMIT 5",
                params={"sid": sid},
                param_types={"sid": spanner.param_types.STRING},
            ))
            for n in neighbors:
                expanded_context.append(f"- [{n[2]}] {n[0]}: {n[1]}")

    # Step 3: Gemini summarization
    context_text = "\n\n".join(expanded_context)
    prompt = (
        f"Based on the following knowledge graph context, answer this question:\n\n"
        f"Question: {query}\n\n"
        f"Context:\n{context_text}\n\n"
        f"Provide a concise, grounded answer citing specific nodes."
    )
    response = gemini.generate_content(prompt)

    return jsonify({
        "answer": response.text,
        "sources": [{"node_id": s[0], "title": s[1]} for s in seeds],
    })


# ─── Health ──────────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "brainweave-mcp-api"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
