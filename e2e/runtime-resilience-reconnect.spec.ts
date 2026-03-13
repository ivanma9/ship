import { expect, test, Page } from './fixtures/isolated-env';
import { waitForEditorReady } from './fixtures/test-helpers';

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

test('stays on the active document during transient reconnect turbulence', async ({ page, context }) => {
  await login(page);
  await createNewDocument(page);

  const currentUrl = page.url();
  let getCount = 0;

  await context.route('**/api/documents/*', async (route) => {
    if (route.request().method() !== 'GET') {
      await route.continue();
      return;
    }

    getCount += 1;
    if (getCount <= 2) {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Transient reconnect failure',
          },
        }),
      });
      return;
    }

    await route.continue();
  });

  await page.reload();
  await expect(page).toHaveURL(currentUrl);
  await waitForEditorReady(page);
});
