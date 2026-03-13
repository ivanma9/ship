-- Migration 038: Add targeted indexes for API list endpoint latency
--
-- Targets two endpoints:
--   /api/documents?type=wiki  (target: P95 ≤ 98ms at c50)
--   /api/issues               (target: P95 ≤ 84ms at c50)
--
-- Decision rationale:
--   EXPLAIN ANALYZE (2026-03-12) showed:
--   1. Wiki list: idx_documents_workspace_id used; filters 250 rows to find 7 wiki docs.
--      Adding a composite covering (workspace_id, document_type, position, created_at)
--      WHERE archived/deleted IS NULL lets the planner skip the per-row filters entirely.
--   2. Issues list: Nested Loop Left Join on person_doc iterates 104 issue rows × 11
--      person docs = 1040 extra comparisons because idx_documents_person_user_id lacks
--      workspace_id. New composite partial index adds workspace_id to that index.
--
-- Rollback:
--   DROP INDEX IF EXISTS idx_documents_list_active_type;
--   DROP INDEX IF EXISTS idx_documents_person_workspace_user;

-- 1. Composite index for wiki/document list queries
--    Covers: WHERE workspace_id=? AND document_type=? AND archived_at IS NULL AND deleted_at IS NULL
--    Plus ORDER BY position ASC, created_at DESC
CREATE INDEX IF NOT EXISTS idx_documents_list_active_type
  ON documents (workspace_id, document_type, position ASC, created_at DESC)
  WHERE archived_at IS NULL AND deleted_at IS NULL;

-- 2. Composite index for person_doc join in issue list query
--    Covers: person_doc.workspace_id = d.workspace_id AND document_type = 'person'
--            AND person_doc.properties->>'user_id' = d.properties->>'assignee_id'
--    Turns the nested loop (104 × 11 scans) into an index lookup per issue
CREATE INDEX IF NOT EXISTS idx_documents_person_workspace_user
  ON documents (workspace_id, (properties->>'user_id'))
  WHERE document_type = 'person';
