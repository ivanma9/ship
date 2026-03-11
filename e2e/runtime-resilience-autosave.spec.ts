import { expect, test, Page } from './fixtures/isolated-env';

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
}

test('shows sticky autosave failure and clears it after a later successful save', async ({ page, context }) => {
  await login(page);
  await createNewDocument(page);

  let shouldFail = true;
  await context.route('**/api/documents/*', async (route) => {
    if (route.request().method() !== 'PATCH') {
      await route.continue();
      return;
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

  await expect(page.getByRole('alert')).toContainText('Changes are local only until save succeeds.');

  shouldFail = false;
  await titleInput.fill('Recovered Title');

  await expect(page.getByRole('alert')).not.toBeVisible({ timeout: 10000 });
});
