import { expect, test, type Page } from './fixtures/isolated-env';
import type { Browser, BrowserContext } from '@playwright/test';
import {
  typeInEditorWithRetry,
  waitForConvergedEditors,
  waitForEditorReady,
  waitForEditorText,
  waitForSavedReload,
  waitForSyncStatus,
} from './fixtures/test-helpers';

async function createUserContext(browser: Browser): Promise<BrowserContext> {
  const context = await browser.newContext();
  await context.addInitScript(() => {
    localStorage.setItem('ship:disableActionItemsModal', 'true');
  });
  return context;
}

async function login(page: Page, email: string, password = 'admin123') {
  await page.goto('/login');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL(/\/login($|\?)/, { timeout: 5000 });
}

async function createSharedDocument(page: Page, title: string, body: string): Promise<string> {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: /new document/i }).first().click();
  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);

  const titleInput = page.locator('textarea[placeholder="Untitled"]');
  await titleInput.fill(title);

  const editor = page.locator('.ProseMirror');
  await typeInEditorWithRetry(page, body);
  await waitForEditorText(page, body);
  await waitForSyncStatus(page);
  await waitForSavedReload(page);
  await waitForEditorText(page, body);

  return page.url();
}

test('concurrent overlap edits converge and persist after reload', async ({ browser }) => {
  const aliceContext = await createUserContext(browser);
  const bobContext = await createUserContext(browser);
  const alicePage = await aliceContext.newPage();
  const bobPage = await bobContext.newPage();

  try {
    await login(alicePage, 'alice.chen@ship.local');
    await login(bobPage, 'bob.martinez@ship.local');

    const docUrl = await createSharedDocument(
      alicePage,
      'Concurrent Overlap Convergence',
      'Shared convergence baseline',
    );

    await bobPage.goto(docUrl);
    await waitForEditorReady(bobPage);
    await waitForSyncStatus(alicePage);
    await waitForSyncStatus(bobPage);
    await waitForConvergedEditors([alicePage, bobPage], (text) => {
      expect(text).toContain('Shared convergence baseline');
    });

    const aliceEditor = alicePage.locator('.ProseMirror');
    const bobEditor = bobPage.locator('.ProseMirror');

    await aliceEditor.click();
    await alicePage.keyboard.press('End');
    await bobEditor.click();
    await bobPage.keyboard.press('End');

    await Promise.all([
      alicePage.keyboard.type(' [ALICE-OVERLAP]'),
      bobPage.keyboard.type(' [BOB-OVERLAP]'),
    ]);

    const convergedText = await waitForConvergedEditors([alicePage, bobPage], (text) => {
      expect(text).toContain('ALICE-OVERLAP');
      expect(text).toContain('BOB-OVERLAP');
    });

    await waitForSyncStatus(alicePage);
    await waitForSyncStatus(bobPage);
    await waitForSavedReload(alicePage);
    await waitForSavedReload(bobPage);

    const reloadedText = await waitForConvergedEditors([alicePage, bobPage], (text) => {
      expect(text).toContain('ALICE-OVERLAP');
      expect(text).toContain('BOB-OVERLAP');
    });

    expect(reloadedText).toBe(convergedText);
  } finally {
    await aliceContext.close();
    await bobContext.close();
  }
});
