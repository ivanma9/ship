-- Why: document_associations is joined in nearly every route (issues, programs, dashboard,
-- activity) but lacks a covering index on (document_id, relationship_type, related_id).
-- The existing single-column indexes force PostgreSQL to do index intersections or full scans.
-- These two covering indexes make all EXISTS/IN/JOIN lookups index-only scans.
--
-- Rollback:
--   DROP INDEX IF EXISTS idx_doc_assoc_doc_type_related;
--   DROP INDEX IF EXISTS idx_doc_assoc_related_type_doc;

-- Covering index: document_id → relationship_type → related_id
-- Used by: issues.ts EXISTS filters, documents.ts belongs_to lookups
CREATE INDEX IF NOT EXISTS idx_doc_assoc_doc_type_related
  ON document_associations (document_id, relationship_type, related_id);

-- Reverse covering index: related_id → relationship_type → document_id
-- Used by: programs.ts COUNT queries, dashboard.ts project status subqueries
CREATE INDEX IF NOT EXISTS idx_doc_assoc_related_type_doc
  ON document_associations (related_id, relationship_type, document_id);
