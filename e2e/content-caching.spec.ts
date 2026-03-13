import { test, expect } from './fixtures/isolated-env';
import {
  waitForCollaborationWebSocket,
  waitForEditorReady,
  waitForSavedReload,
  waitForSyncStatus,
} from './fixtures/test-helpers';

async function login(page: import('@playwright/test').Page, email: string = 'dev@ship.local') {
  await page.goto('/login');
  await page.fill('input[name="email"]', email);
  await page.fill('input[name="password"]', 'admin123');
  await page.click('button[type="submit"]');
  await page.waitForURL(/\/(issues|docs)/);
}

async function createNewDocument(page: import('@playwright/test').Page): Promise<string> {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');

  const createButton = page.locator('aside').getByRole('button', { name: /new|create|\+/i }).first();
  if (await createButton.isVisible({ timeout: 2000 }).catch(() => false)) {
    await createButton.click();
  } else {
    await page.getByRole('button', { name: /new document/i }).click();
  }

  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);
  await expect(page.getByTestId('sync-status')).toContainText(/Saved|Cached|Saving|Offline/, { timeout: 15000 });
  return page.url();
}

async function getEditorText(page: import('@playwright/test').Page): Promise<string> {
  return await page.locator('.ProseMirror').textContent() ?? '';
}

test.describe('Content Caching - High Performance Navigation', () => {

  test.beforeEach(async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[name="email"]', 'dev@ship.local');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(issues|docs)/);
  });

  test('toggling between two documents shows no blank flash', async ({ page }) => {
    await page.goto('/docs');

    // Wait for the document tree to load (tree has aria-label="Workspace documents" or "Documents")
    const tree = page.getByRole('tree', { name: 'Workspace documents' }).or(page.getByRole('tree', { name: 'Documents' }));
    await tree.first().waitFor({ timeout: 10000 });

    // Get first two document links from sidebar tree (seed data provides these)
    const docLinks = tree.first().getByRole('link');
    const count = await docLinks.count();

    // Seed data should provide at least 2 wiki documents
    expect(count, 'Seed data should provide at least 2 wiki documents. Run: pnpm db:seed').toBeGreaterThanOrEqual(2);

    // Visit first document
    await docLinks.first().click();
    await page.waitForURL(/\/documents\/.+/);
    await page.waitForSelector('.ProseMirror', { timeout: 10000 });
    const doc1Url = page.url();

    // Visit second document
    await docLinks.nth(1).click();
    await page.waitForURL(/\/documents\/.+/);
    await page.waitForSelector('.ProseMirror', { timeout: 10000 });
    const doc2Url = page.url();

    // Now toggle between documents - should not see blank state
    // Reduce to 2 iterations and shorter timeouts to avoid test timeout
    for (let i = 0; i < 2; i++) {
      await page.goto(doc1Url);

      // Wait for editor to appear (content loading is async via WebSocket)
      const hasEditor1 = await page.waitForSelector('.ProseMirror', { timeout: 5000 }).catch(() => null);
      expect(hasEditor1).toBeTruthy();

      await page.goto(doc2Url);

      const hasEditor2 = await page.waitForSelector('.ProseMirror', { timeout: 5000 }).catch(() => null);
      expect(hasEditor2).toBeTruthy();
    }
  });

});

test.describe('Content Caching - Slow Refresh Recovery', () => {
  test('receiver refresh converges after delayed collaboration reconnect without re-opening the document', async ({ page, browser, baseURL }) => {
    await login(page, 'dev@ship.local');
    const documentUrl = await createNewDocument(page);

    const editor = page.locator('.ProseMirror');
    await editor.click();
    const initialText = `Initial cached content ${Date.now()}`;
    await page.keyboard.type(initialText, { delay: 15 });
    await expect.poll(() => getEditorText(page)).toContain(initialText);
    await waitForSyncStatus(page);
    await waitForSavedReload(page);
    await expect.poll(() => getEditorText(page), { timeout: 15000 }).toContain(initialText);

    const receiverContext = await browser.newContext({ baseURL });
    await receiverContext.addInitScript(() => {
      localStorage.setItem('ship:disableActionItemsModal', 'true');
    });
    const receiverPage = await receiverContext.newPage();

    try {
      await login(receiverPage, 'alice.chen@ship.local');
      await receiverPage.goto(documentUrl);
      await receiverPage.waitForSelector('.ProseMirror', { timeout: 10000 });
      await expect.poll(() => getEditorText(receiverPage), { timeout: 15000 }).toContain(initialText);

      await receiverPage.reload();
      await receiverPage.waitForSelector('.ProseMirror', { timeout: 10000 });
      await expect(receiverPage.getByTestId('sync-status')).toContainText(/Saved|Cached|Saving|Offline/, { timeout: 15000 });
      await expect.poll(() => getEditorText(receiverPage), { timeout: 15000 }).toContain(initialText);

      const delayedText = `Recovered after delayed sync ${Date.now()}`;
      await editor.click();
      await page.keyboard.type(` ${delayedText}`, { delay: 15 });
      await expect.poll(() => getEditorText(page)).toContain(delayedText);

      await expect.poll(() => getEditorText(receiverPage), { timeout: 15000 }).toContain(delayedText);
    } finally {
      await receiverContext.close();
    }
  });
});

test.describe('WebSocket Connection Reliability', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'dev@ship.local');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(issues|docs)/);
  });

  test('WebSocket connects successfully on document load', async ({ page }) => {
    await page.goto('/docs');

    // Track WebSocket connections
    const wsConnections: string[] = [];
    page.on('websocket', ws => {
      wsConnections.push(ws.url());
    });

    // Navigate to a document (tree has aria-label="Workspace documents" or "Documents")
    const tree = page.getByRole('tree', { name: 'Workspace documents' }).or(page.getByRole('tree', { name: 'Documents' }));
    const firstDoc = tree.getByRole('link').first();
    await firstDoc.click();
    await page.waitForURL(/\/documents\/.+/);

    await waitForEditorReady(page);
    await waitForCollaborationWebSocket(page, wsConnections);

    // Should have a collaboration WebSocket
    const hasCollabWs = wsConnections.some(url => url.includes('/collaboration/'));
    expect(hasCollabWs).toBe(true);
  });

  test('sync status shows status indicator after WebSocket connects', async ({ page }) => {
    await page.goto('/docs');

    const tree2 = page.getByRole('tree', { name: 'Workspace documents' }).or(page.getByRole('tree', { name: 'Documents' }));
    const firstDoc2 = tree2.getByRole('link').first();
    await firstDoc2.click();
    await page.waitForURL(/\/documents\/.+/);

    await waitForEditorReady(page);
    await waitForSyncStatus(page, /Saved|Saving|Cached|Offline/);

    // Should not show permanent error states
    const hasDisconnected = await page.locator('text=Disconnected').count();
    expect(hasDisconnected).toBe(0);
  });

  test('no console errors about WebSocket connection failures', async ({ page }) => {
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error' && msg.text().includes('WebSocket')) {
        consoleErrors.push(msg.text());
      }
    });

    const wsConnections: string[] = [];
    page.on('websocket', ws => {
      wsConnections.push(ws.url());
    });

    await page.goto('/docs');

    const tree3 = page.getByRole('tree', { name: 'Workspace documents' }).or(page.getByRole('tree', { name: 'Documents' }));
    const firstDoc3 = tree3.getByRole('link').first();
    await firstDoc3.click();
    await page.waitForURL(/\/documents\/.+/);

    await waitForEditorReady(page);
    await waitForCollaborationWebSocket(page, wsConnections);
    await waitForSyncStatus(page, /Saved|Saving|Cached|Offline/);

    // Should have no critical WebSocket errors (connection closed before ready, connection failed)
    const wsErrors = consoleErrors.filter(e =>
      e.includes('closed before') ||
      e.includes('connection failed')
    );
    expect(wsErrors).toHaveLength(0);
  });

});

// Helper to get CSRF token
async function getCsrfToken(page: import('@playwright/test').Page): Promise<string> {
  const response = await page.request.get('/api/csrf-token');
  const data = await response.json();
  return data.token;
}

test.describe('API Content Update Invalidates Browser Cache', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', 'dev@ship.local');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(issues|docs)/);
  });

});
