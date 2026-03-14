// audits/artifacts/category6-console-recheck.mjs
import { chromium } from '@playwright/test';
import fs from 'fs';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5173';
const EMAIL = 'dev@ship.local';
const PASSWORD = 'admin123';
const outDir = 'audits/artifacts';
fs.mkdirSync(outDir, { recursive: true });

const logFile = `${outDir}/console-recheck-${Date.now()}.log`;
let consoleErrors = 0;
const errorLines = [];

async function run() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on('console', (msg) => {
    const entry = `[${new Date().toISOString()}] ${msg.type()}: ${msg.text()}`;
    fs.appendFileSync(logFile, entry + '\n');
    if (msg.type() === 'error') {
      consoleErrors += 1;
      errorLines.push(entry);
    }
  });

  page.on('pageerror', (err) => {
    const entry = `[${new Date().toISOString()}] pageerror: ${String(err)}`;
    fs.appendFileSync(logFile, entry + '\n');
    consoleErrors += 1;
    errorLines.push(entry);
  });

  // Login — handles both /login and /setup flows
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
  await page.waitForTimeout(1500); // let post-login fetches settle

  const pages = [
    '/dashboard',
    '/my-week',
    '/docs',
    '/issues',
    '/projects',
    '/programs',
    '/team/allocation',
    '/settings',
  ];

  for (const path of pages) {
    await page.goto(`${BASE_URL}${path}`);
    await page.waitForTimeout(2000);
  }

  await browser.close();

  const result = {
    capturedAt: new Date().toISOString(),
    totalConsoleErrors: consoleErrors,
    target: 5,
    pass: consoleErrors <= 5,
    errorLines,
    logFile,
  };

  const outFile = `${outDir}/category6-recheck-result.json`;
  fs.writeFileSync(outFile, JSON.stringify(result, null, 2));

  console.log('\n=== Category 6 Console Error Re-check ===');
  console.log(`Total console errors: ${consoleErrors}`);
  console.log(`Target: ≤5`);
  console.log(`Result: ${result.pass ? 'PASS' : 'FAIL'}`);
  if (errorLines.length > 0) {
    console.log('\nError lines:');
    errorLines.forEach(l => console.log(' ', l));
  }
  console.log(`\nFull log: ${logFile}`);
  console.log(`Result JSON: ${outFile}`);
}

run().catch((err) => { console.error(err); process.exit(1); });
