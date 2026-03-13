import { test, expect, type Page } from './fixtures/isolated-env'
import { typeInEditorWithRetry, waitForEditorReady, waitForSyncStatus } from './fixtures/test-helpers'

/**
 * Tests that /my-week reflects plan/retro edits after navigating back.
 *
 * Bug: The my-week query had a 5-minute staleTime and content edits go through
 * Yjs WebSocket (no client-side mutation), so navigating back showed stale data.
 * Fix: staleTime set to 0 so every mount refetches fresh data from the API.
 *
 */

test.describe('My Week - stale data after editing plan/retro', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.locator('#email').fill('dev@ship.local')
    await page.locator('#password').fill('admin123')
    await page.getByRole('button', { name: 'Sign in', exact: true }).click()
    await expect(page).not.toHaveURL('/login', { timeout: 5000 })
  })

  async function waitForDocumentApiContent(page: Page, expectedText: string): Promise<void> {
    const match = page.url().match(/\/documents\/([a-f0-9-]+)/)
    const documentId = match?.[1]
    expect(documentId, 'Expected to be on a document URL before polling document API').toBeTruthy()

    await expect.poll(async () => {
      return page.evaluate(async ({ id }) => {
        const response = await fetch(`/api/documents/${id}`, { credentials: 'include' })
        if (!response.ok) return ''
        const data = await response.json()
        return JSON.stringify(data.content ?? '')
      }, { id: documentId! })
    }, {
      timeout: 60000,
      intervals: [250, 500, 1000, 2000, 5000],
    }).toContain(expectedText)
  }

  async function typeIntoFirstEditableWeeklySlot(page: Page, text: string): Promise<void> {
    const listParagraph = page.locator('.ProseMirror li p').first()
    const rootParagraph = page.locator('.ProseMirror > p').first()

    await expect(async () => {
      if (await listParagraph.count()) {
        await listParagraph.click({ position: { x: 12, y: 12 } })
      } else if (await rootParagraph.count()) {
        await rootParagraph.click({ position: { x: 12, y: 12 } })
      } else {
        await typeInEditorWithRetry(page, text)
        return
      }

      await page.keyboard.type(text)
      await expect.poll(async () => page.locator('.ProseMirror').textContent(), {
        timeout: 10000,
        intervals: [250, 500, 1000],
      }).toContain(text)
    }).toPass({ timeout: 20000, intervals: [500, 1000, 2000] })
  }

  test('plan edits are visible on /my-week after navigating back', async ({ page }) => {
    // 1. Navigate to /my-week
    await page.goto('/my-week')
    await expect(page.getByRole('heading', { name: /^Week \d+$/ })).toBeVisible({ timeout: 10000 })

    // 2. Create a plan (click the create button)
    await page.getByRole('button', { name: /create plan for this week/i }).click()

    // 3. Should navigate to the document editor
    await expect(page).toHaveURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 })

    // 4. Wait for the TipTap editor to be ready
    await waitForEditorReady(page)
    await waitForSyncStatus(page)

    // 5. The plan template already provides empty bullet items; fill the first one.
    await typeIntoFirstEditableWeeklySlot(page, 'Ship the new dashboard feature')

    // 6. Wait for collaborative persistence before polling the API-backed document payload.
    await waitForDocumentApiContent(page, 'Ship the new dashboard feature')

    // 7. Navigate back to /my-week using client-side navigation (Dashboard icon in rail)
    await page.getByRole('button', { name: 'Dashboard' }).click()
    await expect(page.getByRole('heading', { name: /^Week \d+$/ })).toBeVisible({ timeout: 10000 })

    // 8. Verify the plan content is visible on the my-week page
    // The my-week API reads from the `content` column which is updated by the
    // collaboration server's persistence layer after collaborative sync.
    await expect.poll(async () => page.locator('body').textContent(), {
      timeout: 15000,
      intervals: [250, 500, 1000],
    }).toContain('Ship the new dashboard feature')
  })

  test('retro edits are visible on /my-week after navigating back', async ({ page }) => {
    // 1. Navigate to /my-week
    await page.goto('/my-week')
    await expect(page.getByRole('heading', { name: /^Week \d+$/ })).toBeVisible({ timeout: 10000 })

    // 2. Create a retro (click the main create button, not the nudge link)
    await page.getByRole('button', { name: /create retro for this week/i }).click()

    // 3. Should navigate to the document editor
    await expect(page).toHaveURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 })

    // 4. Wait for the TipTap editor to be ready
    await waitForEditorReady(page)
    await waitForSyncStatus(page)

    // 5. Type a list item into the editor
    await typeIntoFirstEditableWeeklySlot(page, 'Completed the API refactoring')

    // 6. Wait for collaborative persistence before polling the API-backed document payload.
    await waitForDocumentApiContent(page, 'Completed the API refactoring')

    // 7. Navigate back to /my-week using client-side navigation
    await page.getByRole('button', { name: 'Dashboard' }).click()
    await expect(page.getByRole('heading', { name: /^Week \d+$/ })).toBeVisible({ timeout: 10000 })

    // 8. Verify the retro content is visible on the my-week page
    await expect.poll(async () => page.locator('body').textContent(), {
      timeout: 15000,
      intervals: [250, 500, 1000],
    }).toContain('Completed the API refactoring')
  })
})
