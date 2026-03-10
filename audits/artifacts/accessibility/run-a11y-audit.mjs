#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const BASE_URL = process.env.SHIP_BASE_URL || 'http://localhost:5174';
const EMAIL = process.env.SHIP_EMAIL || 'dev@ship.local';
const PASSWORD = process.env.SHIP_PASSWORD || 'admin123';

const now = new Date();
const stamp = now.toISOString().replace(/[:.]/g, '-');
const outputDir = path.resolve(process.cwd(), `audits/artifacts/accessibility/results/${stamp}`);
fs.mkdirSync(outputDir, { recursive: true });

const pages = [
  { name: 'Login', path: '/login', requiresAuth: false },
  { name: 'Dashboard', path: '/dashboard', requiresAuth: true },
  { name: 'My Week', path: '/my-week', requiresAuth: true },
  { name: 'Docs', path: '/docs', requiresAuth: true },
  { name: 'Issues', path: '/issues', requiresAuth: true },
  { name: 'Projects', path: '/projects', requiresAuth: true },
  { name: 'Programs', path: '/programs', requiresAuth: true },
  { name: 'Team Allocation', path: '/team/allocation', requiresAuth: true },
  { name: 'Settings', path: '/settings', requiresAuth: true },
];

function run(cmd, args, opts = {}) {
  const result = spawnSync(cmd, args, {
    encoding: 'utf8',
    stdio: 'pipe',
    ...opts,
  });

  return {
    status: result.status ?? 1,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
  };
}

function scoreFromLighthouseReport(filePath) {
  const report = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const raw = report?.categories?.accessibility?.score;
  if (typeof raw !== 'number') return null;
  return Math.round(raw * 100);
}

function summarizeAxe(violations) {
  const severityCounts = {
    critical: 0,
    serious: 0,
    moderate: 0,
    minor: 0,
  };

  const missingAriaOrLabel = [];
  const colorContrastFailures = [];

  for (const v of violations) {
    const impact = (v.impact || 'minor').toLowerCase();
    const count = Array.isArray(v.nodes) ? v.nodes.length : 0;
    if (severityCounts[impact] !== undefined) {
      severityCounts[impact] += count;
    } else {
      severityCounts.minor += count;
    }

    const isAriaOrLabel =
      v.id.includes('aria') ||
      v.id.includes('label') ||
      v.id === 'button-name' ||
      v.id === 'link-name';
    if (isAriaOrLabel) {
      for (const node of v.nodes || []) {
        missingAriaOrLabel.push({
          rule: v.id,
          impact: impact,
          target: node.target?.join(' > ') || '(unknown target)',
          summary: node.failureSummary || '',
        });
      }
    }

    if (v.id === 'color-contrast') {
      for (const node of v.nodes || []) {
        colorContrastFailures.push({
          impact: impact,
          target: node.target?.join(' > ') || '(unknown target)',
          summary: node.failureSummary || '',
        });
      }
    }
  }

  return { severityCounts, missingAriaOrLabel, colorContrastFailures };
}

async function keyboardCoverage(page) {
  const focusableSelector = [
    'a[href]',
    'button:not([disabled])',
    'input:not([disabled]):not([type="hidden"])',
    'select:not([disabled])',
    'textarea:not([disabled])',
    '[tabindex]:not([tabindex="-1"])',
    '[role="button"]',
    '[role="link"]',
    '[role="checkbox"]',
    '[role="radio"]',
    '[role="tab"]',
    '[role="menuitem"]',
  ].join(', ');

  const focusableCount = await page.evaluate((selector) => {
    const els = Array.from(document.querySelectorAll(selector));
    const visible = els.filter((el) => {
      const rect = el.getBoundingClientRect();
      const style = window.getComputedStyle(el);
      return rect.width > 0
        && rect.height > 0
        && style.visibility !== 'hidden'
        && style.display !== 'none';
    });
    const dedup = new Set(
      visible.map((el) => {
        const id = el.getAttribute('id') || '';
        const name = el.getAttribute('name') || '';
        const aria = el.getAttribute('aria-label') || '';
        const text = (el.textContent || '').trim().slice(0, 40);
        return `${el.tagName}|${id}|${name}|${aria}|${text}`;
      }),
    );
    return dedup.size;
  }, focusableSelector);

  const maxTabs = Math.min(Math.max(focusableCount + 15, 30), 240);
  const visited = new Set();

  for (let i = 0; i < maxTabs; i += 1) {
    await page.keyboard.press('Tab');
    const sig = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el || el === document.body) return '';
      const id = el.getAttribute('id') || '';
      const name = el.getAttribute('name') || '';
      const aria = el.getAttribute('aria-label') || '';
      const role = el.getAttribute('role') || '';
      const text = (el.textContent || '').trim().slice(0, 40);
      return `${el.tagName}|${id}|${name}|${aria}|${role}|${text}`;
    });
    if (sig) visited.add(sig);
  }

  const reached = visited.size;
  const ratio = focusableCount > 0 ? reached / focusableCount : 1;
  const completeness = ratio >= 0.9 ? 'Full' : ratio >= 0.5 ? 'Partial' : 'Broken';

  return { focusableCount, reached, ratio, completeness };
}

async function loginAndGetCookie(browser, outputStatePath) {
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle' });
  await page.fill('input[name="email"]', EMAIL);
  await page.fill('input[name="password"]', PASSWORD);
  await Promise.all([
    page.waitForURL((url) => !url.pathname.startsWith('/login'), { timeout: 20000 }),
    page.click('button[type="submit"]'),
  ]);
  await page.waitForLoadState('networkidle');

  await context.storageState({ path: outputStatePath });
  const cookies = await context.cookies();
  await context.close();

  const cookieHeader = cookies.map((c) => `${c.name}=${c.value}`).join('; ');
  return cookieHeader;
}

function runLighthouseForPage(url, cookieHeader, outFile) {
  const chromePath = chromium.executablePath();
  const args = [
    'dlx',
    'lighthouse@12',
    url,
    '--only-categories=accessibility',
    '--preset=desktop',
    '--chrome-flags=--headless=new --no-sandbox --disable-dev-shm-usage',
    '--output=json',
    `--output-path=${outFile}`,
    '--quiet',
    `--chrome-path=${chromePath}`,
  ];

  if (cookieHeader) {
    args.push(`--extra-headers=${JSON.stringify({ Cookie: cookieHeader })}`);
  }

  return run('pnpm', args);
}

async function main() {
  console.log(`Audit output directory: ${outputDir}`);

  const browser = await chromium.launch({ headless: true });
  const storageStatePath = path.join(outputDir, 'storage-state.json');

  let cookieHeader = '';
  try {
    cookieHeader = await loginAndGetCookie(browser, storageStatePath);
    if (!cookieHeader) {
      throw new Error('No cookies captured after login');
    }
  } catch (error) {
    await browser.close();
    throw error;
  }

  const authenticatedContext = await browser.newContext({ storageState: storageStatePath });
  const page = await authenticatedContext.newPage();

  const results = [];
  for (const pageDef of pages) {
    const url = `${BASE_URL}${pageDef.path}`;
    console.log(`\nAuditing ${pageDef.name}: ${url}`);

    let lighthouseScore = null;
    const lighthouseOut = path.join(
      outputDir,
      `lighthouse-${pageDef.name.toLowerCase().replace(/\s+/g, '-')}.json`,
    );
    const lighthouse = runLighthouseForPage(
      url,
      pageDef.requiresAuth ? cookieHeader : '',
      lighthouseOut,
    );
    if (lighthouse.status === 0 && fs.existsSync(lighthouseOut)) {
      lighthouseScore = scoreFromLighthouseReport(lighthouseOut);
    }

    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);

    const axe = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'section508'])
      .analyze();
    const axeSummary = summarizeAxe(axe.violations);

    const keyboard = await keyboardCoverage(page);
    const snapshotPath = path.join(
      outputDir,
      `screenshot-${pageDef.name.toLowerCase().replace(/\s+/g, '-')}.png`,
    );
    await page.screenshot({ path: snapshotPath, fullPage: true });

    const semanticSummary = await page.evaluate(() => {
      const headingCount = document.querySelectorAll('h1,h2,h3,h4,h5,h6,[role="heading"]').length;
      const landmarkCount = document.querySelectorAll(
        'main,nav,header,footer,aside,section,[role="main"],[role="navigation"],[role="banner"],[role="contentinfo"],[role="region"]',
      ).length;
      return { headingCount, landmarkCount };
    });

    results.push({
      page: pageDef.name,
      path: pageDef.path,
      lighthouseScore,
      lighthouseStatus: lighthouse.status,
      lighthouseError: lighthouse.status === 0 ? '' : lighthouse.stderr || lighthouse.stdout,
      axeViolationCount: axe.violations.length,
      axeInapplicableCount: axe.inapplicable.length,
      severityCounts: axeSummary.severityCounts,
      colorContrastFailures: axeSummary.colorContrastFailures,
      missingAriaOrLabel: axeSummary.missingAriaOrLabel,
      keyboard,
      screenReaderProxy: {
        headingCount: semanticSummary.headingCount,
        landmarkCount: semanticSummary.landmarkCount,
      },
    });
  }

  await authenticatedContext.close();
  await browser.close();

  const summary = {
    generatedAt: now.toISOString(),
    baseUrl: BASE_URL,
    pages,
    results,
  };

  const summaryPath = path.join(outputDir, 'summary.json');
  fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));

  console.log('\nAccessibility audit complete.');
  console.log(`Summary: ${summaryPath}`);
}

main().catch((error) => {
  console.error('\nAccessibility audit failed.');
  console.error(error);
  process.exit(1);
});
