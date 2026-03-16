import { chromium } from '@playwright/test';
import fs from 'fs';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5173';
const API_URL = process.env.API_URL || 'http://localhost:3000';
const EMAIL = 'dev@ship.local';
const PASSWORD = 'admin123';

const outDir = 'audits/artifacts';
fs.mkdirSync(outDir, { recursive: true });

const metrics = {
  reconnectRecovery: 'Unknown',
  redirectChurnCount: 0,
  abortedRequestsDuringReconnect: 0,
  sessionExpiredRedirects: 0,
  consoleErrorsDuringReconnect: 0,
  postReconnectEditsPreserved: false,
  offlineEditsPreserved: false,
  notes: [],
};

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
  const newDocButton = page.getByRole('button', { name: 'New Document', exact: true }).last();
  await newDocButton.waitFor({ state: 'visible', timeout: 15000 });
  await newDocButton.click();
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

  // Track redirects and aborted requests during reconnect window
  let reconnectWindowActive = false;
  page.on('console', (msg) => {
    if (reconnectWindowActive && msg.type() === 'error') {
      metrics.consoleErrorsDuringReconnect += 1;
    }
  });
  page.on('requestfailed', (req) => {
    if (reconnectWindowActive) {
      metrics.abortedRequestsDuringReconnect += 1;
    }
  });
  page.on('response', (res) => {
    const url = res.url();
    if (/login\?expired=true/i.test(url)) {
      metrics.sessionExpiredRedirects += 1;
    }
  });
  page.on('framenavigated', (frame) => {
    if (reconnectWindowActive && /login\?expired=true/i.test(frame.url())) {
      metrics.redirectChurnCount += 1;
    }
  });

  await login(page);
  const docId = await createDoc(page);
  const editor = page.locator('.ProseMirror');

  // Warm up: type some content while online
  await editor.click();
  await page.keyboard.type(' pre-disconnect-content ', { delay: 5 });
  await page.waitForTimeout(1500);

  // Go offline for 10 seconds, type during offline
  reconnectWindowActive = true;
  await context.setOffline(true);
  metrics.notes.push('Went offline');

  await editor.click();
  await page.keyboard.type(' offline-edit-1 offline-edit-2 ', { delay: 5 });
  await page.waitForTimeout(10000);

  // Come back online
  await context.setOffline(false);
  metrics.notes.push('Came back online');
  await page.waitForTimeout(4000); // allow reconnect to settle
  reconnectWindowActive = false;

  // Verify content is still present (offline edits not lost)
  const bodyText = await editor.textContent().catch(() => '');
  metrics.offlineEditsPreserved = bodyText.includes('offline-edit-1');

  // Type post-reconnect to verify editor is still functional
  await editor.click();
  await page.keyboard.type(' post-reconnect-verify ', { delay: 5 });
  await page.waitForTimeout(1500);

  const bodyTextAfter = await editor.textContent().catch(() => '');
  metrics.postReconnectEditsPreserved = bodyTextAfter.includes('post-reconnect-verify');

  // Determine overall recovery status
  if (metrics.redirectChurnCount > 2) {
    metrics.reconnectRecovery = 'Failure — redirect churn';
  } else if (!metrics.offlineEditsPreserved || !metrics.postReconnectEditsPreserved) {
    metrics.reconnectRecovery = 'Partial — content loss detected';
  } else {
    metrics.reconnectRecovery = 'Success';
  }

  metrics.notes.push(`Session expired redirects: ${metrics.sessionExpiredRedirects}`);
  metrics.notes.push(`Aborted requests during reconnect: ${metrics.abortedRequestsDuringReconnect}`);
  metrics.notes.push(`Console errors during reconnect: ${metrics.consoleErrorsDuringReconnect}`);

  await browser.close();

  const outPath = `${outDir}/category6-disconnect-recheck.json`;
  fs.writeFileSync(outPath, JSON.stringify(metrics, null, 2));
  console.log(JSON.stringify(metrics, null, 2));
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
