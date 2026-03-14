import { chromium } from '@playwright/test';
import fs from 'fs';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5173';
const API_URL = 'http://localhost:3000';
const EMAIL = 'dev@ship.local';
const PASSWORD = 'admin123';
const outDir = 'audits/artifacts';
fs.mkdirSync(outDir, { recursive: true });

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
  } else {
    await page.locator('#email').fill(EMAIL);
    await page.locator('#password').fill(PASSWORD);
    await signInButton.click();
    await page.waitForURL((url) => !url.toString().includes('/login'), { timeout: 10000 });
  }
  await page.waitForTimeout(1000);
}

async function createDoc(page) {
  await page.goto(`${BASE_URL}/docs`);
  await page.waitForTimeout(2000);
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

  // User A
  const ctx1 = await browser.newContext();
  const page1 = await ctx1.newPage();
  await login(page1);
  const docId = await createDoc(page1);
  console.log('Doc created:', docId);

  // User B — login and navigate to same doc
  const ctx2 = await browser.newContext();
  const page2 = await ctx2.newPage();
  await login(page2);
  await page2.goto(`${BASE_URL}/documents/${docId}`);
  await page2.locator('.ProseMirror').waitFor({ state: 'visible', timeout: 10000 });
  await page2.waitForTimeout(1000); // let Yjs sync settle

  // Concurrent title collision — 50ms window
  const t1 = page1.locator('textarea[placeholder="Untitled"]');
  const t2 = page2.locator('textarea[placeholder="Untitled"]');

  const v1 = `UserA-${Date.now()}`;
  const v2 = `UserB-${Date.now()}`;

  await Promise.all([
    (async () => { await t1.click(); await t1.fill(v1); })(),
    (async () => { await page2.waitForTimeout(50); await t2.click(); await t2.fill(v2); })()
  ]);

  await page1.waitForTimeout(3000);
  await page2.waitForTimeout(3000);

  const finalA = await t1.inputValue();
  const finalB = await t2.inputValue();

  const serverRes = await page1.request.get(`${API_URL}/api/documents/${docId}`);
  const serverJson = await serverRes.json().catch(() => ({}));
  const serverTitle = serverJson?.title ?? serverJson?.document?.title ?? null;

  const converged = finalA === finalB;
  const serverMatchesA = serverTitle === finalA;
  const serverMatchesB = serverTitle === finalB;

  const result = {
    capturedAt: new Date().toISOString(),
    attemptedA: v1,
    attemptedB: v2,
    clientAFinal: finalA,
    clientBFinal: finalB,
    serverFinal: serverTitle,
    clientsConverged: converged,
    serverMatchesAClient: serverMatchesA,
    serverMatchesBClient: serverMatchesB,
    inference: converged ? 'Converged (Last-Write-Wins resolved)' : 'Divergence observed',
  };

  fs.writeFileSync(`${outDir}/category6-collision-recheck.json`, JSON.stringify(result, null, 2));

  console.log('\n=== Yjs Collision Re-check ===');
  console.log('Attempted A:', v1);
  console.log('Attempted B:', v2);
  console.log('Client A final:', finalA);
  console.log('Client B final:', finalB);
  console.log('Server final:', serverTitle);
  console.log('Clients converged:', converged);
  console.log('Inference:', result.inference);

  await ctx2.close();
  await browser.close();
}

run().catch((err) => { console.error(err); process.exit(1); });
