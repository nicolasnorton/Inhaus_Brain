-- ═══════════════════════════════════════════════════════════════════════════════
-- BrainWeave 3.0 — arscontexta + GitNexus Evolution Schema (Additive Only)
-- Feature Flag: BRAINWEAVE_3_0_EVOLUTION_ENABLED
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Evolve BrainWeaveAnnotations: add agent provenance + voting
--    (existing columns: annotation_id, node_id, owner_id, text, provenance, created_at)
ALTER TABLE BrainWeaveAnnotations ADD COLUMN agent_id STRING(128);
ALTER TABLE BrainWeaveAnnotations ADD COLUMN vote_score INT64 DEFAULT (0);

-- 2. BrainWeaveSkills — dedicated skill table (evolution of GitNexus clustering)
--    Skills are promoted instinct clusters with executability + safety scoring.
CREATE TABLE BrainWeaveSkills (
  skill_id          STRING(36) NOT NULL,
  node_id           STRING(36),
  owner_id          STRING(128) NOT NULL,
  name              STRING(512),
  description       STRING(MAX),
  workflow_steps    STRING(MAX),
  safety_score      FLOAT64,
  executability_score FLOAT64,
  confidence        FLOAT64,
  instinct_ids      ARRAY<STRING(36)>,
  source_agent      STRING(128),
  last_evaluated    TIMESTAMP,
  created_at        TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  updated_at        TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
) PRIMARY KEY (skill_id);

-- 3. BrainWeaveMemex — long-term memory archive (arscontexta evergreen + GitNexus incremental)
--    Stores compacted summaries with recall priority for context windowing.
CREATE TABLE BrainWeaveMemex (
  memex_id          STRING(36) NOT NULL,
  node_id           STRING(36),
  owner_id          STRING(128) NOT NULL,
  summary           STRING(MAX),
  full_archive_uri  STRING(1024),
  recall_priority   FLOAT64,
  source_agent      STRING(128),
  created_at        TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
) PRIMARY KEY (memex_id);
