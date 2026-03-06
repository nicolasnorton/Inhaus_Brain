-- ═══════════════════════════════════════════════════════════
-- BrainWeave 2.0 — Spanner FGAC (Fine-Grained Access Control)
-- Run via: gcloud spanner databases ddl update brainweave
--          --instance=brainweave-graph --ddl-file=infra/spanner_fgac.sql
-- ═══════════════════════════════════════════════════════════

-- ─── FGAC Roles ─────────────────────────────────────────────
CREATE ROLE brainweave_reader;
CREATE ROLE brainweave_writer;
CREATE ROLE brainweave_superadmin;

-- ─── Reader: SELECT only ────────────────────────────────────
GRANT SELECT ON TABLE BrainWeaveNodes TO ROLE brainweave_reader;
GRANT SELECT ON TABLE BrainWeaveEdges TO ROLE brainweave_reader;
GRANT SELECT ON TABLE BrainWeaveSessions TO ROLE brainweave_reader;
GRANT SELECT ON TABLE PendingPromotions TO ROLE brainweave_reader;

-- ─── Writer: Full CRUD on nodes/edges, limited on promotions ─
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE BrainWeaveNodes TO ROLE brainweave_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE BrainWeaveEdges TO ROLE brainweave_writer;
GRANT SELECT, INSERT, UPDATE ON TABLE PendingPromotions TO ROLE brainweave_writer;
GRANT SELECT, INSERT, UPDATE ON TABLE BrainWeaveSessions TO ROLE brainweave_writer;

-- ─── Superadmin: Everything ─────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE BrainWeaveNodes TO ROLE brainweave_superadmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE BrainWeaveEdges TO ROLE brainweave_superadmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE PendingPromotions TO ROLE brainweave_superadmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE BrainWeaveSessions TO ROLE brainweave_superadmin;
