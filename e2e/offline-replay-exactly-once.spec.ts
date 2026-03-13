import { expect, test, type Page } from './fixtures/isolated-env';
import {
  getEditorTextWithoutCursor,
  typeInEditorWithRetry,
  waitForEditorReady,
  waitForEditorText,
  waitForOfflineState,
  waitForSavedReload,
  waitForSyncRecovered,
  waitForSyncStatus,
} from './fixtures/test-helpers';

async function login(page: Page, email = 'alice.chen@ship.local', password = 'admin123') {
  await page.goto('/login');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL(/\/login($|\?)/, { timeout: 5000 });
}

async function createDocument(page: Page, title: string, body: string): Promise<void> {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: /new document/i }).first().click();
  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);

  await page.locator('textarea[placeholder="Untitled"]').fill(title);
  await typeInEditorWithRetry(page, body);
  await waitForEditorText(page, body);
  await waitForSyncStatus(page);
  await waitForSavedReload(page);
  await waitForEditorText(page, body);
}

test('offline edits replay exactly once after reconnect and reload', async ({ page, context }) => {
  await login(page);
  await createDocument(page, 'Offline Replay Exactly Once', 'Online baseline ');

  const editor = page.locator('.ProseMirror');
  const replayToken = `OFFLINE-REPLAY-${Date.now()}`;

  await editor.click();
  await context.setOffline(true);
  await waitForOfflineState(page);
  await page.keyboard.type(`${replayToken} `);

  await expect(editor).toContainText(replayToken);

  await context.setOffline(false);
  await waitForSyncRecovered(page);
  await waitForSyncStatus(page);
  await waitForSavedReload(page);

  const text = await getEditorTextWithoutCursor(page);
  const occurrences = text.match(new RegExp(replayToken, 'g')) ?? [];
  expect(occurrences).toHaveLength(1);
  expect(text).toContain('Online baseline');

  await typeInEditorWithRetry(page, 'Post-reconnect follow-up');
  await waitForEditorText(page, 'Post-reconnect follow-up');
  await waitForSyncStatus(page);
});
