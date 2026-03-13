#!/usr/bin/env bash
# scripts/count-type-violations.sh
# Counts core type-safety violations across api/src, web/src, shared/src.
# Exits non-zero if count exceeds MAX_VIOLATIONS.
#
# Usage: ./scripts/count-type-violations.sh [max_violations]
# Default max: 416 (25% below baseline of 554)

set -euo pipefail

MAX=${1:-416}

ANY_COUNT=$(grep -rn ": any\b\|as any\b\|any\[\]\|<any>" \
  --include="*.ts" --include="*.tsx" api/src web/src shared/src 2>/dev/null \
  | grep -v "\.d\.ts" | wc -l | tr -d ' ')

BANG_COUNT=$(grep -rEn "[a-zA-Z0-9_)]+![^=]" \
  --include="*.ts" --include="*.tsx" \
  api/src web/src 2>/dev/null \
  | grep -v "\.d\.ts\|//\|!==" | wc -l | tr -d ' ')

SUPPRESS_COUNT=$(grep -rn "@ts-ignore\|@ts-expect-error\|@ts-nocheck" \
  --include="*.ts" --include="*.tsx" api/src web/src 2>/dev/null | wc -l | tr -d ' ')

TOTAL=$((ANY_COUNT + BANG_COUNT + SUPPRESS_COUNT))

echo "Type violation counts:"
echo "  any annotations/assertions: ${ANY_COUNT}"
echo "  non-null assertions (!):    ${BANG_COUNT}"
echo "  ts-ignore/suppress:         ${SUPPRESS_COUNT}"
echo "  TOTAL:                      ${TOTAL}"
echo "  MAX ALLOWED:                ${MAX}"

if [ "$TOTAL" -gt "$MAX" ]; then
  echo ""
  echo "ERROR: Type violation count (${TOTAL}) exceeds maximum allowed (${MAX})."
  echo "Fix type violations before merging, or update the MAX argument in ci.yml"
  echo "if the increase is intentional and documented."
  exit 1
fi

echo ""
echo "OK: Type violation count (${TOTAL}) is within allowed maximum (${MAX})."
