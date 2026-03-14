#!/usr/bin/env node
/**
 * type-violation-scan.cjs
 *
 * AST-based scan for TypeScript type-safety violations.
 * Counts: any, as assertions, non-null assertions (!), @ts-ignore/@ts-expect-error,
 *         untyped function parameters, missing explicit return types.
 *
 * Usage:
 *   node scripts/type-violation-scan.cjs
 *   node scripts/type-violation-scan.cjs --json   # outputs raw JSON
 */

const fs = require('fs');
const path = require('path');
const ts = require('typescript');

const SCAN_DIRS = ['api/src', 'web/src', 'shared/src'];
const ROOT = path.resolve(__dirname, '..');

function walk(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, files);
    } else if (/\.(ts|tsx)$/.test(entry.name) && !entry.name.endsWith('.d.ts')) {
      files.push(full);
    }
  }
  return files;
}

function scanFile(filePath) {
  const src = fs.readFileSync(filePath, 'utf8');
  const sf = ts.createSourceFile(filePath, src, ts.ScriptTarget.Latest, true);

  let anyCount = 0;
  let asCount = 0;
  let nonNullCount = 0;
  let suppressCount = 0;
  let untypedParams = 0;
  let missingReturnTypes = 0;

  // Count @ts-ignore / @ts-expect-error via regex on raw source
  suppressCount = (src.match(/@ts-(ignore|expect-error)/g) || []).length;

  function visit(node) {
    // `any` keyword
    if (node.kind === ts.SyntaxKind.AnyKeyword) {
      anyCount++;
    }

    // `as` type assertions (but not `as const` — those are safe)
    if (node.kind === ts.SyntaxKind.AsExpression) {
      const typeNode = node.type;
      if (!(typeNode && typeNode.kind === ts.SyntaxKind.TypeReference &&
            typeNode.typeName && typeNode.typeName.text === 'const')) {
        asCount++;
      }
    }

    // Non-null assertions
    if (node.kind === ts.SyntaxKind.NonNullExpression) {
      nonNullCount++;
    }

    // Untyped function parameters
    if (
      node.kind === ts.SyntaxKind.Parameter &&
      node.parent &&
      (
        node.parent.kind === ts.SyntaxKind.FunctionDeclaration ||
        node.parent.kind === ts.SyntaxKind.MethodDeclaration ||
        node.parent.kind === ts.SyntaxKind.ArrowFunction ||
        node.parent.kind === ts.SyntaxKind.FunctionExpression
      )
    ) {
      if (!node.type && !node.dotDotDotToken) {
        untypedParams++;
      }
    }

    // Missing explicit return types on named functions / methods / arrows assigned to typed vars
    if (
      node.kind === ts.SyntaxKind.FunctionDeclaration ||
      node.kind === ts.SyntaxKind.MethodDeclaration
    ) {
      if (!node.type) {
        missingReturnTypes++;
      }
    }

    ts.forEachChild(node, visit);
  }

  visit(sf);

  return { anyCount, asCount, nonNullCount, suppressCount, untypedParams, missingReturnTypes };
}

function getPackage(filePath) {
  const rel = path.relative(ROOT, filePath);
  if (rel.startsWith('api/')) return 'api/';
  if (rel.startsWith('web/')) return 'web/';
  if (rel.startsWith('shared/')) return 'shared/';
  return 'other/';
}

// ── Main ──────────────────────────────────────────────────────────────────────

const allFiles = SCAN_DIRS.flatMap(d => walk(path.join(ROOT, d)));

const byPackage = {};
const byFile = [];

let totals = { anyCount: 0, asCount: 0, nonNullCount: 0, suppressCount: 0, untypedParams: 0, missingReturnTypes: 0 };

for (const f of allFiles) {
  const counts = scanFile(f);
  const pkg = getPackage(f);
  if (!byPackage[pkg]) byPackage[pkg] = { anyCount: 0, asCount: 0, nonNullCount: 0, suppressCount: 0, untypedParams: 0, missingReturnTypes: 0 };
  for (const k of Object.keys(counts)) {
    byPackage[pkg][k] += counts[k];
    totals[k] += counts[k];
  }
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  if (total > 0) byFile.push({ file: path.relative(ROOT, f), ...counts, total });
}

byFile.sort((a, b) => b.total - a.total);

const core = totals.anyCount + totals.asCount + totals.nonNullCount + totals.suppressCount;
const grand = Object.values(totals).reduce((a, b) => a + b, 0);

const result = {
  scannedFiles: allFiles.length,
  date: new Date().toISOString().slice(0, 10),
  core,
  grand,
  totals,
  byPackage,
  top10: byFile.slice(0, 10),
};

if (process.argv.includes('--json')) {
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log(`\nType Violation Scan — ${result.date}`);
  console.log(`Files scanned: ${result.scannedFiles}`);
  console.log(`\nCore metric (any + as + ! + @ts-*): ${core}`);
  console.log(`Grand total (all 6 categories):     ${grand}`);
  console.log(`\nPer-package:`);
  for (const [pkg, c] of Object.entries(byPackage)) {
    const pkgCore = c.anyCount + c.asCount + c.nonNullCount + c.suppressCount;
    console.log(`  ${pkg.padEnd(12)} any=${c.anyCount} as=${c.asCount} !=${c.nonNullCount} @ts-*=${c.suppressCount} core=${pkgCore} total=${Object.values(c).reduce((a,b)=>a+b,0)}`);
  }
  console.log(`\nTop 10 files by total violations:`);
  for (const f of byFile.slice(0, 10)) {
    console.log(`  ${f.total.toString().padStart(4)}  ${f.file}`);
  }
}
