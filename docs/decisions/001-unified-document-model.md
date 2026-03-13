# ADR-001: Unified Document Model

**Date:** 2026-01-06
**Status:** Accepted
**Deciders:** Ivan Ma

## Context

The app needed to store wikis, issues, projects, sprints, programs, and people. The naive approach would be a separate table per type (issues table, projects table, etc.). This is common but creates duplication of editor logic, collaboration infrastructure, and API patterns for every new type.

## Decision

Everything is stored in a single `documents` table with a `document_type` field. Type-specific properties live in a JSONB `properties` column. Relationships between documents use the `document_associations` junction table.

## Why

Notion proved this model works at scale. The real difference between a wiki and an issue is metadata, not structure. A unified model means one editor component, one collaboration server, one set of API patterns — all reused across every document type. Adding a new document type costs near zero.

## Consequences

**Good:** Single `Editor` component, one WebSocket collaboration server, uniform API, trivially extensible to new types.
**Bad:** JSONB properties sacrifice relational query ergonomics; migrations that add typed columns must touch one table but affect all types.
**Risks:** If document types diverge significantly in structure, the unified model becomes a leaky abstraction.

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| Separate table per type | N tables × N migrations × N API routes — multiplication of maintenance cost |
| Polymorphic associations (STI) | Same underlying problem, just hidden behind an ORM |
