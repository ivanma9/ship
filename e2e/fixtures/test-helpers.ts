/**
 * Reusable test helpers for flaky-resistant E2E test patterns.
 *
 * These helpers encapsulate retry logic for common interactions that
 * fail under parallel test load due to timing issues.
 */
import { expect, type Locator, type Page } from '@playwright/test';

const DEFAULT_SYNC_STATUS = /Saved|Cached/;

export async function waitForEditorReady(page: Page): Promise<void> {
  await expect(page.locator('.ProseMirror')).toBeVisible({ timeout: 10000 });
  await expect(page.locator('textarea[placeholder="Untitled"]')).toBeVisible({ timeout: 5000 });
}

export async function waitForSyncStatus(
  page: Page,
  status: RegExp = DEFAULT_SYNC_STATUS,
): Promise<void> {
  await expect(page.getByTestId('sync-status').getByText(status)).toBeVisible({ timeout: 15000 });
}

export async function waitForOfflineState(page: Page): Promise<void> {
  await expect(page.getByTestId('sync-status')).toContainText(/offline/i, { timeout: 15000 });
}

export async function waitForSyncRecovered(page: Page): Promise<void> {
  await expect(page.getByTestId('sync-status')).toBeVisible({ timeout: 15000 });
  await expect.poll(async () => {
    const statusText = await page.getByTestId('sync-status').textContent();
    return statusText?.trim() ?? '';
  }, {
    timeout: 15000,
    intervals: [250, 500, 1000],
  }).not.toMatch(/offline/i);
}

export async function waitForUrlChangeAway(page: Page, previousUrl: string): Promise<void> {
  await expect.poll(() => page.url(), {
    timeout: 15000,
    intervals: [250, 500, 1000],
  }).not.toBe(previousUrl);
}

export async function waitForCollaborationWebSocket(_page: Page, urls: string[]): Promise<void> {
  await expect.poll(() => {
    return urls.some((url) => url.includes('/collaboration/'));
  }, {
    timeout: 10000,
    intervals: [100, 250, 500, 1000],
  }).toBe(true);
}

export async function waitForSavedReload(page: Page): Promise<void> {
  await page.reload();
  await waitForEditorReady(page);
  await waitForSyncStatus(page);
}

export async function getEditorTextWithoutCursor(page: Page): Promise<string> {
  const editor = page.locator('.ProseMirror').first();
  return editor.evaluate((node) => {
    const clone = node.cloneNode(true) as HTMLElement;
    clone.querySelectorAll('.collaboration-cursor__label, .collaboration-cursor__caret').forEach((el) => el.remove());
    return clone.textContent ?? '';
  });
}

export async function waitForEditorText(page: Page, text: string | RegExp): Promise<void> {
  if (typeof text === 'string') {
    await expect.poll(async () => getEditorTextWithoutCursor(page), {
      timeout: 15000,
    }).toContain(text);
    return;
  }

  await expect.poll(async () => getEditorTextWithoutCursor(page), {
    timeout: 15000,
  }).toMatch(text);
}

export async function typeInEditorWithRetry(page: Page, text: string): Promise<void> {
  const editor = page.locator('.ProseMirror').first();

  await expect(async () => {
    await editor.click({ position: { x: 12, y: 12 } });
    await expect(editor).toBeFocused({ timeout: 3000 });
    await editor.pressSequentially(text);
    await waitForEditorText(page, text);
  }).toPass({ timeout: 30000, intervals: [1000, 2000, 3000, 5000] });
}

export async function waitForConvergedEditors(
  pages: Page[],
  assertion: (text: string) => void,
): Promise<string> {
  let finalText = '';

  await expect.poll(async () => {
    const texts = await Promise.all(pages.map((page) => getEditorTextWithoutCursor(page)));
    const normalized = texts.map((text) => text.replace(/\s+/g, ' ').trim());
    const first = normalized[0] ?? '';
    if (!normalized.every((text) => text === first)) {
      return '__not_converged__';
    }
    finalText = first;
    assertion(first);
    return first;
  }, {
    timeout: 20000,
    intervals: [250, 500, 1000],
  }).not.toBe('__not_converged__');

  return finalText;
}

/**
 * Trigger the TipTap mention autocomplete popup by typing '@' in the editor.
 *
 * Under parallel load, the '@' keystroke may not trigger the mention popup
 * on the first attempt — the editor may not be focused, the mention extension
 * may not be initialized, or the keystroke may be swallowed. This helper
 * retries by re-clicking the editor, clearing content, and retyping '@'
 * until the popup appears.
 *
 * @param page - The Playwright page (or second page in multi-context tests)
 * @param editor - Locator for the .ProseMirror editor element
 * @returns Locator for the mention popup listbox (already confirmed visible)
 *
 * @example
 * const editor = page.locator('.ProseMirror')
 * await triggerMentionPopup(page, editor)
 * await page.keyboard.type('Document Name')
 * const option = page.locator('[role="option"]').filter({ hasText: 'Document Name' })
 * await option.click()
 */
export async function triggerMentionPopup(page: Page, editor: Locator): Promise<Locator> {
  const mentionPopup = page.locator('[role="listbox"]');
  await expect(async () => {
    await editor.click();
    await expect(editor).toBeFocused({ timeout: 3000 });
    await page.keyboard.press('Tab').catch(() => {});
    await editor.click();
    await expect(editor).toBeFocused({ timeout: 3000 });
    await page.keyboard.press('Meta+End').catch(() => {});
    await page.keyboard.press('Control+End').catch(() => {});
    await page.keyboard.press('ArrowRight').catch(() => {});
    await page.keyboard.type('@');
    const popupVisible = await expect
      .poll(async () => mentionPopup.isVisible().catch(() => false), {
        timeout: 3000,
        intervals: [100, 250, 500],
      })
      .toBeTruthy()
      .then(() => true)
      .catch(() => false);
    if (!popupVisible) {
      await page.keyboard.press('Backspace');
      throw new Error('Mention popup did not open');
    }
  }).toPass({ timeout: 30000, intervals: [1000, 2000, 3000, 4000, 5000] });
  await expect(mentionPopup).toBeVisible({ timeout: 5000 });
  return mentionPopup;
}

/**
 * Hover over an element and verify an assertion, with retry.
 *
 * Under parallel load, Playwright's hover() may not trigger the expected
 * React state update (e.g., onMouseEnter setting focus or revealing a checkbox).
 * This can happen when the DOM shifts due to late-loading data, or when the
 * hover event fires on a stale element reference. This helper retries the
 * hover + assertion until it succeeds.
 *
 * @param target - The element to hover over
 * @param assertion - An async function containing the expect assertion to verify after hover
 *
 * @example
 * // Verify focus ring appears on hover
 * await hoverWithRetry(rows.nth(2), async () => {
 *   await expect(rows.nth(2)).toHaveAttribute('data-focused', 'true', { timeout: 3000 })
 * })
 *
 * // Verify checkbox becomes visible on hover
 * await hoverWithRetry(firstRow, async () => {
 *   await expect(checkboxContainer).toHaveCSS('opacity', '1', { timeout: 3000 })
 * })
 */
export async function hoverWithRetry(
  target: Locator,
  assertion: () => Promise<void>,
): Promise<void> {
  await expect(async () => {
    await target.hover();
    await assertion();
  }).toPass({ timeout: 10000, intervals: [500, 1000, 2000] });
}

/**
 * Wait for a data table to be fully loaded and stable before interacting.
 *
 * Under parallel load, tables may render incrementally — the first few rows
 * appear, then more data arrives causing re-renders that shift row positions.
 * Interacting with rows during this unstable period causes hover/click to
 * target the wrong element. This helper waits for both the first row to
 * render AND network activity to settle.
 *
 * @param page - The Playwright page
 * @param tableSelector - CSS selector for the table body rows (default: 'table tbody tr')
 *
 * @example
 * await waitForTableData(page)
 * // Table is now stable — safe to hover, click, or count rows
 * const rows = page.locator('tbody tr')
 * await hoverWithRetry(rows.first(), async () => { ... })
 */
export async function waitForTableData(
  page: Page,
  tableSelector = 'table tbody tr',
): Promise<void> {
  await expect(page.locator(tableSelector).first()).toBeVisible({ timeout: 15000 });
  await page.waitForLoadState('networkidle');
}
