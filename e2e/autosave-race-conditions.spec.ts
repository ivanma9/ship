import { test, expect, Page } from './fixtures/isolated-env';
import { waitForEditorReady, waitForSyncStatus } from './fixtures/test-helpers';

/**
 * Auto-Save Race Condition Tests
 *
 * Tests that verify the auto-save mechanism prevents stale server responses
 * from overwriting local state during active typing.
 *
 * Key scenario: User types "Hello", pauses, server saves "Hello", user continues
 * typing "Hello World", stale server response should NOT overwrite to "Hello".
 */

// Helper to login
async function login(page: Page, email: string = 'dev@ship.local', password: string = 'admin123') {
  await page.context().clearCookies();
  await page.goto('/login');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL('/login', { timeout: 5000 });
}

// Helper to create a new document and wait for editor
async function createNewDocument(page: Page) {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');

  const currentUrl = page.url();
  // Button uses aria-label, not title attribute
  const newDocButton = page.getByRole('button', { name: /new document/i });
  await expect(newDocButton.first()).toBeVisible({ timeout: 5000 });
  await newDocButton.first().click();

  await page.waitForFunction(
    (oldUrl) => window.location.href !== oldUrl && /\/documents\/[a-f0-9-]+/.test(window.location.href),
    currentUrl,
    { timeout: 10000 }
  );

  await waitForEditorReady(page);
}

// Helper to create a new issue
async function createNewIssue(page: Page) {
  await page.goto('/issues');
  await page.waitForLoadState('networkidle');

  // Use the sidebar button with aria-label (there's also a text button "New Issue" in main content)
  const newIssueButton = page.getByRole('button', { name: 'New issue', exact: true });
  await expect(newIssueButton).toBeVisible({ timeout: 5000 });
  await newIssueButton.click();

  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);
}

async function waitForNextDocumentPatch(page: Page): Promise<void> {
  await page.waitForResponse(
    (response) =>
      response.url().includes('/api/documents/')
      && response.request().method() === 'PATCH',
    { timeout: 15000 },
  );
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

test.describe('Auto-Save Race Conditions - Title Field', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('type-pause-type: stale response does not overwrite local title', async ({ page }) => {
    await createNewDocument(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');

    // Type first part of title
    await titleInput.click();
    const firstPatch = waitForNextDocumentPatch(page);
    await titleInput.fill('Hello');
    await firstPatch;

    // Continue typing while server response may be in-flight
    const secondPatch = waitForNextDocumentPatch(page);
    await titleInput.fill('Hello World');
    await titleInput.blur();
    await secondPatch;
    await waitForSyncStatus(page);

    // Title should be "Hello World", NOT reverted to "Hello"
    await expect(titleInput).toHaveValue('Hello World');

    // Reload to verify "Hello World" was actually saved
    await page.reload();
    await waitForEditorReady(page);
    await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue('Hello World');
  });

  test('rapid typing with throttle: intermediate saves do not overwrite', async ({ page }) => {
    await createNewDocument(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');
    // Use focus() instead of click() and wait for focus to be established
    await titleInput.focus();
    await expect(titleInput).toBeFocused({ timeout: 2000 });

    // Type character by character with small delays (simulates real typing)
    const fullTitle = 'This is a long title that takes time to type';
    await page.keyboard.type(fullTitle, { delay: 50 });
    await titleInput.blur();

    await waitForDocumentPatchTitle(page, fullTitle);
    await waitForSyncStatus(page);

    // Title should be the full string, not truncated by intermediate saves
    await expect(titleInput).toHaveValue(fullTitle);

    // Reload to verify full title was saved
    await page.reload();
    await waitForEditorReady(page);
    await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue(fullTitle);
  });

  test('multiple pause-resume cycles preserve all changes', async ({ page }) => {
    await createNewDocument(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');
    await titleInput.click();

    // First segment
    let patch = waitForNextDocumentPatch(page);
    await titleInput.fill('Part 1');
    await patch;

    // Second segment
    patch = waitForNextDocumentPatch(page);
    await titleInput.fill('Part 1 and Part 2');
    await patch;

    // Third segment
    patch = waitForNextDocumentPatch(page);
    await titleInput.fill('Part 1 and Part 2 and Part 3');
    await titleInput.blur();
    await patch;
    await waitForSyncStatus(page);

    // Should have complete title
    await expect(titleInput).toHaveValue('Part 1 and Part 2 and Part 3');

    // Reload to verify
    await page.reload();
    await waitForEditorReady(page);
    await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue('Part 1 and Part 2 and Part 3');
  });

  test('issue title: stale response does not overwrite', async ({ page }) => {
    await createNewIssue(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');

    // Type first part
    await titleInput.click();
    let patch = waitForNextDocumentPatch(page);
    await titleInput.fill('Bug:');
    await patch;

    // Continue typing
    patch = waitForNextDocumentPatch(page);
    await titleInput.fill('Bug: login fails');
    await titleInput.blur();
    await patch;
    await waitForSyncStatus(page);

    // Should have full title
    await expect(titleInput).toHaveValue('Bug: login fails');

    // Reload to verify
    await page.reload();
    await waitForEditorReady(page);
    await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue('Bug: login fails');
  });
});

test.describe('Auto-Save Race Conditions - Throttle Behavior', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('throttle: saves periodically during long typing session', async ({ page, context }) => {
    // Track API calls
    const apiCalls: { timestamp: number; title: string }[] = [];
    await context.route('**/api/documents/**', async (route) => {
      const request = route.request();
      if (request.method() === 'PATCH') {
        try {
          const body = request.postDataJSON();
          if (body?.title) {
            apiCalls.push({ timestamp: Date.now(), title: body.title });
          }
        } catch {
          // Ignore parse errors
        }
      }
      await route.continue();
    });

    await createNewDocument(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');
    await titleInput.click();

    // Type continuously for 3 seconds
    await page.keyboard.type('a'.repeat(30), { delay: 100 });
    await titleInput.blur();

    await expect.poll(() => apiCalls.length, { timeout: 15000 }).toBeGreaterThanOrEqual(3);

    // With throttle (500ms), we should have multiple saves during 3s of typing
    // Expect at least 3-4 intermediate saves (not just one at the end like debounce)
    expect(apiCalls.length).toBeGreaterThanOrEqual(3);

    // Verify final title was saved correctly
    const currentValue = await titleInput.inputValue();
    await waitForDocumentPatchTitle(page, currentValue);
    await waitForSyncStatus(page);
    await page.reload();
    await waitForEditorReady(page);
    await expect(page.locator('textarea[placeholder="Untitled"]')).toHaveValue(currentValue);
  });
});

test.describe('Auto-Save Race Conditions - Error Recovery', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('failed save is retried silently', async ({ page, context }) => {
    await createNewDocument(page);

    const titleInput = page.locator('textarea[placeholder="Untitled"]');
    await titleInput.click();

    // Set up route to fail first request, succeed on retry
    let requestCount = 0;
    await context.route('**/api/documents/**', async (route) => {
      const request = route.request();
      if (request.method() === 'PATCH') {
        requestCount++;
        if (requestCount === 1) {
          // First request fails
          await route.abort('failed');
        } else {
          // Subsequent requests succeed
          await route.continue();
        }
      } else {
        await route.continue();
      }
    });

    // Type title
    await titleInput.fill('Retryable Title');
    await titleInput.blur();
    await expect.poll(() => requestCount, { timeout: 15000 }).toBeGreaterThanOrEqual(2);

    // Remove route interception
    await context.unrouteAll();

    await waitForSyncStatus(page);

    // Verify it was eventually saved (via retry)
    await page.reload();
    await waitForEditorReady(page);
    // Should have the title (either from retry or subsequent save)
    const finalTitle = await page.locator('textarea[placeholder="Untitled"]').inputValue();
    expect(finalTitle).toContain('Retryable');
  });
});

test.describe('Auto-Save Race Conditions - Slow Network', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('slow response does not overwrite faster local changes', async ({ page, context }) => {
    await createNewDocument(page);

    // Slow down PATCH responses significantly
    let patchCount = 0;
    await context.route('**/api/documents/**', async (route) => {
      const request = route.request();
      if (request.method() === 'PATCH') {
        patchCount++;
        // Delay response by 2 seconds
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
      await route.continue();
    });

    const titleInput = page.locator('textarea[placeholder="Untitled"]');
    await titleInput.click();

    // Type "Slow" - this will trigger a save that takes 2s to respond
    await titleInput.fill('Slow');
    await expect.poll(() => patchCount, { timeout: 5000 }).toBeGreaterThanOrEqual(1);

    // Immediately type more - while first response is still pending
    await titleInput.fill('Slow and Fast');

    await titleInput.fill('Slow and Fast and Final');
    await titleInput.blur();

    await waitForSyncStatus(page);

    // Should have the final value, not reverted to "Slow"
    await expect(titleInput).toHaveValue('Slow and Fast and Final');
  });
});
