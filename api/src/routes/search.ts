import { Router, Response } from 'express';
import { AuthenticatedRequest, authHandler } from '../types/express.js';
import { pool } from '../db/client.js';
import { authMiddleware } from '../middleware/auth.js';
import { isWorkspaceAdmin } from '../middleware/visibility.js';

type RouterType = ReturnType<typeof Router>;
export const searchRouter: RouterType = Router();

type MentionSearchSource = 'person' | 'document';

type MentionSearchRow = {
  source_type: MentionSearchSource;
  id: string;
  name: string | null;
  title: string | null;
  document_type: 'person' | 'wiki' | 'issue' | 'project' | 'program';
  visibility: string | null;
  source_order: string | number;
};

type MentionPersonResult = {
  id: string;
  name: string;
  document_type: 'person';
};

type MentionDocumentResult = {
  id: string;
  title: string;
  document_type: 'wiki' | 'issue' | 'project' | 'program';
  visibility: string | null;
};

// SECURITY: Escape SQL LIKE pattern special characters to prevent wildcard injection
// This prevents users from using % and _ to match arbitrary patterns
function escapeLikePattern(str: string): string {
  return str.replace(/[%_\\]/g, '\\$&');
}

// Search for mentions (people + documents)
// GET /api/search/mentions?q=:query
searchRouter.get('/mentions', authMiddleware, authHandler(async (req: AuthenticatedRequest, res: Response) => {
  try {
    const searchQuery = (req.query.q as string) || '';
    const workspaceId = req.workspaceId;
    const userId = req.userId;

    // SECURITY: Escape wildcard characters to prevent SQL wildcard injection
    const sanitizedQuery = escapeLikePattern(searchQuery);

    // Check if user is admin for visibility filtering
    const isAdmin = await isWorkspaceAdmin(userId, workspaceId);

    const mentionResult = await pool.query<MentionSearchRow>(
      `WITH people_matches AS (
         SELECT
           'person'::text AS source_type,
           person_rows.id,
           person_rows.name,
           NULL::text AS title,
           'person'::text AS document_type,
           NULL::text AS visibility,
           ROW_NUMBER() OVER (ORDER BY person_rows.name ASC, person_rows.id ASC) AS source_order
         FROM (
           SELECT
             d.id::text AS id,
             d.title AS name
           FROM documents d
           WHERE d.workspace_id = $1
             AND d.document_type = 'person'
             AND d.archived_at IS NULL
             AND d.deleted_at IS NULL
             AND d.title ILIKE $2
           ORDER BY d.title ASC, d.id ASC
           LIMIT 5
         ) person_rows
       ),
       document_matches AS (
         SELECT
           'document'::text AS source_type,
           document_rows.id,
           NULL::text AS name,
           document_rows.title,
           document_rows.document_type,
           document_rows.visibility,
           ROW_NUMBER() OVER (
             ORDER BY document_rows.type_rank ASC, document_rows.updated_at DESC, document_rows.id ASC
           ) AS source_order
         FROM (
           SELECT
             d.id::text AS id,
             d.title,
             d.document_type::text AS document_type,
             d.visibility::text AS visibility,
             d.updated_at,
             CASE d.document_type
               WHEN 'issue' THEN 1
               WHEN 'wiki' THEN 2
               WHEN 'project' THEN 3
               WHEN 'program' THEN 4
               ELSE 5
             END AS type_rank
           FROM documents d
           WHERE d.workspace_id = $1
             AND d.document_type IN ('wiki', 'issue', 'project', 'program')
             AND d.deleted_at IS NULL
             AND d.archived_at IS NULL
             AND d.title ILIKE $2
             AND (d.visibility = 'workspace' OR d.created_by = $3 OR $4 = TRUE)
           ORDER BY
             type_rank ASC,
             d.updated_at DESC,
             d.id ASC
           LIMIT 10
         ) document_rows
       )
       SELECT source_type, id, name, title, document_type, visibility, source_order
       FROM people_matches
       UNION ALL
       SELECT source_type, id, name, title, document_type, visibility, source_order
       FROM document_matches
       ORDER BY source_type ASC, source_order ASC`,
      [workspaceId, `%${sanitizedQuery}%`, userId, isAdmin]
    );

    const people: MentionPersonResult[] = [];
    const documents: MentionDocumentResult[] = [];

    for (const row of mentionResult.rows) {
      if (row.source_type === 'person') {
        if (!row.name) {
          continue;
        }

        people.push({
          id: row.id,
          name: row.name,
          document_type: 'person',
        });
        continue;
      }

      if (!row.title) {
        continue;
      }

      documents.push({
        id: row.id,
        title: row.title,
        document_type: row.document_type as MentionDocumentResult['document_type'],
        visibility: row.visibility,
      });
    }

    res.json({
      people,
      documents,
    });
  } catch (error) {
    console.error('Error searching mentions:', error);
    res.status(500).json({ error: 'Failed to search mentions' });
  }
}));

// Search for learning wiki documents
// GET /api/search/learnings?q=:query&program_id=:program_id
searchRouter.get('/learnings', authMiddleware, authHandler(async (req: AuthenticatedRequest, res: Response) => {
  try {
    const searchQuery = (req.query.q as string) || '';
    const programId = req.query.program_id as string | undefined;
    const workspaceId = req.workspaceId;
    const userId = req.userId;
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);

    // SECURITY: Escape wildcard characters to prevent SQL wildcard injection
    const sanitizedQuery = escapeLikePattern(searchQuery);

    // Check if user is admin for visibility filtering
    const isAdmin = await isWorkspaceAdmin(userId, workspaceId);

    // Search for learning wiki documents
    // Match documents where:
    // - title starts with "Learning:" OR properties.tags contains "learning"
    // - AND title/tags match the search query
    const params: (string | boolean | number)[] = [workspaceId, userId, isAdmin];
    let query = `
      SELECT
        d.id,
        d.title,
        prog_da.related_id as program_id,
        d.properties->>'category' as category,
        d.properties->'tags' as tags,
        d.properties->>'source_prd' as source_prd,
        d.properties->>'source_sprint_id' as source_sprint_id,
        d.created_at,
        d.updated_at,
        substring(d.content::text, 1, 500) as content_preview
      FROM documents d
      LEFT JOIN document_associations prog_da ON d.id = prog_da.document_id AND prog_da.relationship_type = 'program'
      WHERE d.workspace_id = $1
        AND d.document_type = 'wiki'
        AND d.archived_at IS NULL
        AND d.deleted_at IS NULL
        AND (d.visibility = 'workspace' OR d.created_by = $2 OR $3 = TRUE)
        AND (
          d.title LIKE 'Learning:%'
          OR d.properties->'tags' ? 'learning'
        )
    `;

    // Add search query filter if provided
    if (searchQuery) {
      params.push(`%${sanitizedQuery}%`);
      const queryParamIndex = params.length;
      query += `
        AND (
          d.title ILIKE $${queryParamIndex}
          OR EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(d.properties->'tags') AS tag
            WHERE tag ILIKE $${queryParamIndex}
          )
          OR d.properties->>'category' ILIKE $${queryParamIndex}
        )
      `;
    }

    // Filter by program if provided
    if (programId) {
      params.push(programId);
      query += ` AND d.id IN (SELECT document_id FROM document_associations WHERE related_id = $${params.length} AND relationship_type = 'program')`;
    }

    params.push(limit);
    query += ` ORDER BY d.updated_at DESC LIMIT $${params.length}`;

    const result = await pool.query(query, params);

    res.json({
      learnings: result.rows,
      total: result.rows.length,
    });
  } catch (error) {
    console.error('Error searching learnings:', error);
    res.status(500).json({ error: 'Failed to search learnings' });
  }
}));
