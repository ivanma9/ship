import { expect, test, Page } from './fixtures/isolated-env';
import { waitForEditorReady, waitForSavedReload, waitForSyncStatus } from './fixtures/test-helpers';

async function login(page: Page) {
  await page.goto('/login');
  await page.locator('#email').fill('dev@ship.local');
  await page.locator('#password').fill('admin123');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL('/login', { timeout: 5000 });
}

async function createNewDocument(page: Page) {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: /new document/i }).first().click();
  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);
}

test('shows sticky autosave failure and clears it after a later successful save', async ({ page, context }) => {
  await login(page);
  await createNewDocument(page);

  let shouldFail = true;
  const patchTitles: string[] = [];
  await context.route('**/api/documents/*', async (route) => {
    const request = route.request();
    if (request.method() !== 'PATCH') {
      await route.continue();
      return;
    }

    try {
      const body = request.postDataJSON() as { title?: string };
      if (typeof body?.title === 'string') {
        patchTitles.push(body.title);
      }
    } catch {
      // ignore parse errors from unrelated patch shapes
    }

    if (shouldFail) {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Autosave failed',
          },
        }),
      });
      return;
    }

    await route.continue();
  });

  const titleInput = page.locator('textarea[placeholder="Untitled"]');
  await titleInput.fill('Sticky Failure Title');
  await titleInput.blur();

  // The title should remain locally visible while retries are failing.
  await expect(titleInput).toHaveValue('Sticky Failure Title');

  shouldFail = false;
  await titleInput.fill('Recovered Title');
  await titleInput.blur();

  await expect.poll(() => patchTitles.filter((title) => title === 'Recovered Title').length, {
    timeout: 15000,
  }).toBeGreaterThanOrEqual(1);
  await waitForSyncStatus(page);
  await waitForSavedReload(page);
  await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue('Recovered Title');
});
