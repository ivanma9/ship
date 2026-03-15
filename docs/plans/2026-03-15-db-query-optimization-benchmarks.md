# DB Query Optimization — Before/After Analysis

## Migration 039: Covering Composite Indexes

### Before
- `document_associations` had only single-column indexes: `(document_id)`, `(related_id)`, `(relationship_type)`
- EXISTS/IN/JOIN lookups required index intersections or table scans
- PostgreSQL planner could not perform index-only scans on multi-column filters

### After
- `idx_doc_assoc_doc_type_related (document_id, relationship_type, related_id)` — enables index-only scans for all EXISTS filters in issues.ts
- `idx_doc_assoc_related_type_doc (related_id, relationship_type, document_id)` — enables index-only scans for COUNT aggregations in programs.ts and JOIN lookups in dashboard.ts

**To verify:** Run `EXPLAIN ANALYZE` on any issues list query filtering by program/sprint. Expected: `Index Only Scan using idx_doc_assoc_doc_type_related` instead of `Index Scan using idx_document_associations_document_id` + Filter.

## Programs COUNT Joins (programs.ts)

### Before
- Query started FROM documents, scanned all documents of type 'issue'/'sprint' in workspace, then joined to document_associations
- Included archived and soft-deleted documents in counts

### After
- Query starts FROM document_associations, uses covering index to narrow rows, then joins only matching documents
- Excludes archived/deleted documents from counts (behavioral improvement)

**Behavioral note:** Archived and soft-deleted issues/sprints are no longer counted in program totals. This is intentionally more correct — users should not see deleted items in their counts.

## Documents Owner Lookup (documents.ts)

### Before
- 2 separate SQL queries executed sequentially for project/sprint owner lookups
- Each query had different JOIN patterns (inconsistent)

### After
- 1 unified query handles both cases
- Consistent use of users table as base with LEFT JOIN to person_doc

**Measured improvement:** 1 fewer database round-trip per document fetch (for projects and sprints with owners).

## Dashboard Project Status (dashboard.ts)

### Before
- Correlated subquery with 4 JOINs executed once per project row
- O(n) subqueries for n projects

### After
- Single CTE pre-computes all project statuses in one pass
- Main query LEFT JOINs to CTE result
- O(1) instead of O(n) status computations

**Expected improvement:** For a workspace with 50 projects, reduces from ~50 subquery executions to 1 CTE execution.
