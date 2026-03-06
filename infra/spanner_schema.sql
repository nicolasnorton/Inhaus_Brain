-- ═══════════════════════════════════════════════════════════
-- BrainWeave 2.0 — Cloud Spanner Graph Schema
-- Pure Google Cloud Edition
-- ═══════════════════════════════════════════════════════════

-- ─── Nodes ──────────────────────────────────────────────
CREATE TABLE BrainWeaveNodes (
  node_id       STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  owner_id      STRING(128) NOT NULL,
  client_id     STRING(128),
  project_id    STRING(128) DEFAULT 'default',
  scope         STRING(16)  NOT NULL DEFAULT 'PRIVATE',

  -- Content
  title         STRING(512) NOT NULL,
  description   STRING(2048),
  content       STRING(MAX),
  node_type     STRING(32)  NOT NULL,
  topics        ARRAY<STRING(256)>,
  markdown_uri  STRING(1024),
  title_tokens    TOKENLIST AS (TOKENIZE_FULLTEXT(title)) HIDDEN,
  content_tokens  TOKENLIST AS (TOKENIZE_FULLTEXT(content)) HIDDEN,

  -- Vector
  embedding     ARRAY<FLOAT32>,

  -- Metadata
  source_agent  STRING(128),
  confidence    FLOAT64 DEFAULT 1.0,
  metadata      JSON,
  version       INT64   DEFAULT 1,
  created_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  updated_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
) PRIMARY KEY (node_id);

-- ANN Vector Index for semantic search
CREATE VECTOR INDEX BrainWeaveNodesEmbeddingIdx
  ON BrainWeaveNodes(embedding)
  OPTIONS (
    distance_type = 'COSINE',
    tree_depth    = 2,
    num_leaves    = 1000
  );

CREATE INDEX NodesByOwner   ON BrainWeaveNodes(owner_id, scope);
CREATE INDEX NodesByClient  ON BrainWeaveNodes(client_id, scope);
CREATE INDEX NodesByType    ON BrainWeaveNodes(node_type);

-- ─── Edges ──────────────────────────────────────────────
CREATE TABLE BrainWeaveEdges (
  edge_id           STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  owner_id          STRING(128) NOT NULL,
  source_node_id    STRING(36) NOT NULL,
  target_node_id    STRING(36) NOT NULL,
  relationship_type STRING(64) NOT NULL,
  weight            FLOAT64 DEFAULT 1.0,
  confidence        FLOAT64 DEFAULT 1.0,
  embedding         ARRAY<FLOAT32>,
  created_at        TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),

  CONSTRAINT FK_Edge_Source FOREIGN KEY (source_node_id) REFERENCES BrainWeaveNodes(node_id),
  CONSTRAINT FK_Edge_Target FOREIGN KEY (target_node_id) REFERENCES BrainWeaveNodes(node_id),
) PRIMARY KEY (edge_id);

CREATE INDEX EdgesBySource ON BrainWeaveEdges(source_node_id);
CREATE INDEX EdgesByTarget ON BrainWeaveEdges(target_node_id);

-- ─── Spanner Graph Definition ───────────────────────────
CREATE PROPERTY GRAPH BrainWeaveGraph
  NODE TABLES (BrainWeaveNodes)
  EDGE TABLES (
    BrainWeaveEdges
      SOURCE KEY (source_node_id) REFERENCES BrainWeaveNodes(node_id)
      DESTINATION KEY (target_node_id) REFERENCES BrainWeaveNodes(node_id)
  );

-- ─── Sessions (6R Pipeline State) ──────────────────────
CREATE TABLE BrainWeaveSessions (
  session_id    STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  owner_id      STRING(128) NOT NULL,
  client_id     STRING(128),
  current_phase STRING(32) NOT NULL DEFAULT 'idle',
  session_logs  ARRAY<STRING(MAX)>,
  raw_input     STRING(MAX),
  created_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  updated_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
) PRIMARY KEY (session_id);

-- ─── Pending Promotions ─────────────────────────────────
CREATE TABLE PendingPromotions (
  promotion_id  STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  node_id       STRING(36) NOT NULL,
  requested_by  STRING(128) NOT NULL,
  reason        STRING(MAX),
  status        STRING(16) DEFAULT 'PENDING',
  created_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
) PRIMARY KEY (promotion_id);

-- ─── Full-Text Search (BM25) ────────────────────────────
CREATE SEARCH INDEX BrainWeaveNodesTextIndex
  ON BrainWeaveNodes(title_tokens, content_tokens);
