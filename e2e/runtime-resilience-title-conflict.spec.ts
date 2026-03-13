import { expect, test, Page } from './fixtures/isolated-env';
import { waitForSavedReload, waitForSyncStatus } from './fixtures/test-helpers';

async function login(page: Page, email: string = 'dev@ship.local') {
  await page.goto('/login');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill('admin123');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL('/login', { timeout: 5000 });
}

async function createNewDocument(page: Page) {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: /new document/i }).first().click();
  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await expect(page.locator('textarea[placeholder="Untitled"]')).toBeVisible();
}

async function waitForDocumentPatchTitle(page: Page, expectedTitle: string): Promise<void> {
  await page.waitForResponse(async (response) => {
    if (!response.url().includes('/api/documents/') || response.request().method() !== 'PATCH') {
      return false;
    }

    try {
      const body = response.request().postDataJSON() as { title?: string };
      return body?.title === expectedTitle;
    } catch {
      return false;
    }
  }, { timeout: 15000 });
}

test('preserves the latest local title through a transient title conflict', async ({ page, context }) => {
  await login(page);
  await createNewDocument(page);

  let patchCount = 0;
  await context.route('**/api/documents/*', async (route) => {
    const request = route.request();
    if (request.method() !== 'PATCH') {
      await route.continue();
      return;
    }

    patchCount += 1;
    if (patchCount === 1) {
      await route.fulfill({
        status: 409,
        contentType: 'application/json',
        body: JSON.stringify({
          error: {
            code: 'WRITE_CONFLICT',
            message: 'Document was updated by another user. Refresh to get the latest changes before retrying.',
          },
          current_title: 'Server Title',
          current_updated_at: '2026-03-11T19:14:22.123Z',
          attempted_title: 'Local Conflict Title',
        }),
      });
      return;
    }

    await route.continue();
  });

  const titleInput = page.locator('textarea[placeholder="Untitled"]');
  await titleInput.fill('Local Conflict Title');
  await titleInput.blur();

  await expect.poll(() => patchCount, { timeout: 15000 }).toBeGreaterThanOrEqual(2);
  await expect(titleInput).toHaveValue('Local Conflict Title');
  await waitForSavedReload(page);
  await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue('Local Conflict Title');
});

test('propagates title updates between two authenticated users on the same document', async ({ page, browser, baseURL }) => {
  await login(page, 'dev@ship.local');
  await createNewDocument(page);

  const titleInput = page.locator('textarea[placeholder="Untitled"]');
  const documentUrl = page.url();
  const devTitle = `Runtime Resilience ${Date.now()}`;
  await titleInput.fill(devTitle);
  await expect(titleInput).toHaveValue(devTitle);

  const aliceContext = await browser.newContext({ baseURL });
  await aliceContext.addInitScript(() => {
    localStorage.setItem('ship:disableActionItemsModal', 'true');
  });
  const alicePage = await aliceContext.newPage();

  try {
    await login(alicePage, 'alice.chen@ship.local');
    await alicePage.goto(documentUrl);

    const aliceTitleInput = alicePage.locator('textarea[placeholder="Untitled"]');
    await expect(aliceTitleInput).toHaveValue(devTitle, { timeout: 10000 });

    const aliceTitle = `${devTitle} Alice`;
    const alicePatch = waitForDocumentPatchTitle(alicePage, aliceTitle);
    await aliceTitleInput.fill(aliceTitle);
    await aliceTitleInput.blur();
    await expect(aliceTitleInput).toHaveValue(aliceTitle);
    await alicePatch;
    await waitForSyncStatus(alicePage);
    await waitForSavedReload(page);
    await expect(titleInput).toHaveValue(aliceTitle);
  } finally {
    await aliceContext.close();
  }
});
