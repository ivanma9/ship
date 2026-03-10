import { chromium } from '@playwright/test';
import fs from 'fs';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5173';
const API_URL = process.env.API_URL || 'http://localhost:3000';
const EMAIL = 'dev@ship.local';
const PASSWORD = 'admin123';

const outDir = 'audits/artifacts';
fs.mkdirSync(outDir, { recursive: true });

const metrics = {
  consoleErrors: 0,
  unhandledRejections: 0,
  reactBoundarySignals: 0,
  server5xx: 0,
  econnresetSignals: 0,
  silentFailures: [],
  missingErrorBoundaries: [],
  reconnectRecovery: 'Unknown',
  notes: [],
  collision: {},
  fuzz: {},
};

function attachObservers(page, label) {
  page.on('console', (msg) => {
    const type = msg.type();
    const text = msg.text();
    if (type === 'error') metrics.consoleErrors += 1;
    if (/Unhandled Promise Rejection|unhandledrejection|Uncaught \(in promise\)/i.test(text)) metrics.unhandledRejections += 1;
    if (/error boundary|Something went wrong|React.*error/i.test(text)) metrics.reactBoundarySignals += 1;
    if (/ECONNRESET|socket hang up|WebSocket is closed/i.test(text)) metrics.econnresetSignals += 1;
    fs.appendFileSync(`${outDir}/console-${label}.log`, `[${new Date().toISOString()}] ${type}: ${text}\n`);
  });

  page.on('pageerror', (err) => {
    metrics.consoleErrors += 1;
    if (/Unhandled Promise Rejection|unhandledrejection|Uncaught \(in promise\)/i.test(String(err))) metrics.unhandledRejections += 1;
    fs.appendFileSync(`${outDir}/pageerror-${label}.log`, `[${new Date().toISOString()}] ${String(err)}\n`);
  });

  page.on('response', async (res) => {
    const status = res.status();
    const url = res.url();
    if (status >= 500) {
      metrics.server5xx += 1;
      fs.appendFileSync(`${outDir}/server5xx.log`, `[${new Date().toISOString()}] ${status} ${url}\n`);
    }
  });

  page.on('requestfailed', (req) => {
    const failure = req.failure();
    const text = `${req.method()} ${req.url()} :: ${failure?.errorText || 'unknown'}`;
    if (/ECONNRESET|net::ERR_CONNECTION_RESET|socket/i.test(text)) metrics.econnresetSignals += 1;
    fs.appendFileSync(`${outDir}/requestfailed.log`, `[${new Date().toISOString()}] ${text}\n`);
  });
}

async function login(page) {
  await page.goto(`${BASE_URL}/login`);
  const setupButton = page.getByRole('button', { name: /create admin account/i });
  const signInButton = page.getByRole('button', { name: 'Sign in', exact: true });
  await setupButton.or(signInButton).first().waitFor({ state: 'visible', timeout: 10000 });

  if (await setupButton.isVisible().catch(() => false)) {
    await page.locator('#name').fill('Dev User');
    await page.locator('#email').fill(EMAIL);
    await page.locator('#password').fill(PASSWORD);
    await page.locator('#confirmPassword').fill(PASSWORD);
    await setupButton.click();
    await page.waitForURL((url) => !url.toString().includes('/setup'), { timeout: 10000 });
    return;
  }

  await page.locator('#email').fill(EMAIL);
  await page.locator('#password').fill(PASSWORD);
  await signInButton.click();
  await page.waitForURL((url) => !url.toString().includes('/login'), { timeout: 10000 });
}

async function createDoc(page) {
  await page.goto(`${BASE_URL}/docs`);
  await page.waitForTimeout(2500);
  const currentUrl = page.url();
  const sidebarButton = page.locator('aside').getByRole('button', { name: /new|create|\+/i }).first();
  const newDocButtons = page.getByRole('button', { name: /new document/i });
  if (await sidebarButton.isVisible().catch(() => false)) {
    await sidebarButton.click();
  } else {
    await newDocButtons.last().waitFor({ state: 'visible', timeout: 30000 });
    await newDocButtons.last().click();
  }
  await page.waitForFunction(
    (oldUrl) => window.location.href !== oldUrl && /\/documents\/[a-f0-9-]+/.test(window.location.href),
    currentUrl,
    { timeout: 15000 }
  );
  await page.locator('.ProseMirror').waitFor({ state: 'visible', timeout: 10000 });
  return page.url().split('/documents/')[1];
}

async function run() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  attachObservers(page, 'main');

  await login(page);
  const docId = await createDoc(page);
  const editor = page.locator('.ProseMirror');
  const title = page.locator('textarea[placeholder="Untitled"]');

  // 10-minute session simulation with periodic edits
  const start = Date.now();
  let tick = 0;
  while (Date.now() - start < 10 * 60 * 1000) {
    await editor.click();
    await page.keyboard.type(` session-${tick} `, { delay: 5 });
    if (tick % 6 === 0) {
      await title.click();
      await title.fill(`Audit Session ${tick}`);
    }
    await page.waitForTimeout(5000);
    tick += 1;
  }

  // Tunnel test: 10s offline during high-frequency sync
  await editor.click();
  await page.keyboard.type(' pre-disconnect '.repeat(20), { delay: 2 });
  await context.setOffline(true);
  await page.keyboard.type(' during-offline '.repeat(20), { delay: 2 });
  await page.waitForTimeout(10000);
  await context.setOffline(false);
  await page.waitForTimeout(3000);
  await page.keyboard.type(' post-reconnect-check', { delay: 2 });
  const bodyTextAfterReconnect = await editor.textContent();
  const reconnectOk = bodyTextAfterReconnect?.includes('post-reconnect-check') && bodyTextAfterReconnect?.includes('during-offline');
  metrics.reconnectRecovery = reconnectOk ? 'Partial' : 'Failure';
  if (reconnectOk) metrics.reconnectRecovery = 'Success';

  // High latency / slow 3G check via CDP
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', {
    offline: false,
    latency: 400,
    downloadThroughput: 50 * 1024 / 8,
    uploadThroughput: 20 * 1024 / 8,
    connectionType: 'cellular3g'
  });

  await page.goto(`${BASE_URL}/docs`);
  await page.waitForTimeout(2000);
  const loadingIndicators = await page.locator('text=/loading|saving|sync/i').count().catch(() => 0);
  metrics.notes.push(`3G mode load indicators seen: ${loadingIndicators}`);

  // Fuzzing: empty, huge, and injection strings
  await page.goto(`${BASE_URL}/documents/${docId}`);
  await title.click();
  await title.fill('');
  await page.waitForTimeout(800);

  const huge = 'A'.repeat(52000);
  await title.fill(huge);
  await page.waitForTimeout(1200);

  const inj = `<script>alert('x')</script>' OR 1=1; -- {"$ne":null}`;
  await title.fill(inj);
  await editor.click();
  await page.keyboard.type(inj);
  await page.waitForTimeout(1500);

  const contentHtml = await editor.innerHTML();
  metrics.fuzz = {
    hugeLengthAttempted: huge.length,
    injectionPersistedAsRawScriptTag: /<script>alert\('x'\)<\/script>/i.test(contentHtml),
  };

  // Collision test: two users, 50ms window same title field
  const ctx2 = await browser.newContext();
  const page2 = await ctx2.newPage();
  attachObservers(page2, 'peer');
  await login(page2);
  await page2.goto(`${BASE_URL}/documents/${docId}`);
  await page2.locator('.ProseMirror').waitFor({ state: 'visible', timeout: 10000 });

  const t1 = page.locator('textarea[placeholder="Untitled"]');
  const t2 = page2.locator('textarea[placeholder="Untitled"]');

  const v1 = `UserA-${Date.now()}`;
  const v2 = `UserB-${Date.now()}`;

  await Promise.all([
    (async () => { await t1.click(); await t1.fill(v1); })(),
    (async () => { await page2.waitForTimeout(50); await t2.click(); await t2.fill(v2); })()
  ]);

  await page.waitForTimeout(2500);
  await page2.waitForTimeout(2500);

  const finalA = await t1.inputValue();
  const finalB = await t2.inputValue();

  // Verify server persisted title
  const serverDoc = await page.request.get(`${API_URL}/api/documents/${docId}`);
  const serverJson = await serverDoc.json().catch(() => ({}));
  const serverTitle = serverJson?.title ?? serverJson?.document?.title ?? null;

  metrics.collision = {
    attemptedA: v1,
    attemptedB: v2,
    clientAObserved: finalA,
    clientBObserved: finalB,
    serverObserved: serverTitle,
    strategyInference: finalA === finalB ? 'Last-Write-Wins (inferred)' : 'Divergence observed',
  };

  if (serverTitle && (serverTitle !== finalA || serverTitle !== finalB)) {
    metrics.silentFailures.push('Potential zombie state after collision: client and server title diverged');
  }

  // check for visible crash fallback text
  const body = await page.locator('body').textContent();
  if (!/something went wrong|unexpected error/i.test(body || '')) {
    metrics.missingErrorBoundaries.push('/documents route has no user-visible boundary under injected failures');
  }

  await ctx2.close();
  await browser.close();

  fs.writeFileSync(`${outDir}/category6-metrics.json`, JSON.stringify(metrics, null, 2));
  console.log(JSON.stringify(metrics, null, 2));
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
