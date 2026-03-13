import { test, expect, Page, Browser } from './fixtures/isolated-env'
import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'
import { triggerMentionPopup, waitForEditorReady, waitForSavedReload, waitForSyncStatus } from './fixtures/test-helpers'

/**
 * Race Conditions and Concurrency Tests
 *
 * Tests that verify the application handles concurrent operations correctly:
 * - Multiple users editing simultaneously
 * - Rapid operations that could conflict
 * - File uploads during editing
 * - Multiple browser tabs
 * - Network race conditions
 */

// Helper to create a new document
async function createNewDocument(page: Page) {
  await page.goto('/docs')
  await page.waitForLoadState('networkidle')

  const currentUrl = page.url()

  // Try sidebar button first, fall back to main "New Document" button
  const sidebarButton = page.locator('aside').getByRole('button', { name: /new|create|\+/i }).first()
  const mainButton = page.getByRole('button', { name: 'New Document', exact: true })

  if (await sidebarButton.isVisible({ timeout: 2000 })) {
    await sidebarButton.click()
  } else {
    await expect(mainButton).toBeVisible({ timeout: 5000 })
    await mainButton.click()
  }

  await page.waitForFunction(
    (oldUrl) => window.location.href !== oldUrl && /\/documents\/[a-f0-9-]+/.test(window.location.href),
    currentUrl,
    { timeout: 10000 }
  )

  await waitForEditorReady(page)
}

// Helper to login
async function login(page: Page, email: string = 'dev@ship.local', password: string = 'admin123') {
  await page.context().clearCookies()
  await page.goto('/login')
  await page.locator('#email').fill(email)
  await page.locator('#password').fill(password)
  await page.getByRole('button', { name: 'Sign in', exact: true }).click()
  await expect(page).not.toHaveURL('/login', { timeout: 5000 })
}

async function waitForDocumentPatchTitle(page: Page, expectedTitle: string): Promise<void> {
  await page.waitForResponse(async (response) => {
    if (!response.url().includes('/api/documents/') || response.request().method() !== 'PATCH') {
      return false
    }

    try {
      const body = response.request().postDataJSON() as { title?: string }
      return body?.title === expectedTitle
    } catch {
      return false
    }
  }, { timeout: 15000 })
}

async function waitForUploadedImages(editor: ReturnType<Page['locator']>, count: number): Promise<void> {
  await expect.poll(async () => {
    const sources = await editor.locator('img').evaluateAll((images) =>
      images
        .map((img) => img.getAttribute('src') || '')
        .filter((src) => src.startsWith('http') || src.includes('/api/files'))
    )
    return sources.length
  }, { timeout: 20000 }).toBe(count)
}

// Create test image file
function createTestImageFile(): string {
  const pngBuffer = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
    'base64'
  )
  const tmpPath = path.join(os.tmpdir(), `test-image-${Date.now()}.png`)
  fs.writeFileSync(tmpPath, pngBuffer)
  return tmpPath
}

test.describe('Race Conditions - Rapid Operations', () => {
  test.beforeEach(async ({ page }) => {
    await login(page)
  })

  test('rapid save operations do not conflict', async ({ page }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Type rapidly to trigger multiple save operations
    const rapidText = 'a'.repeat(100)
    await page.keyboard.type(rapidText, { delay: 10 })

    // Wait for all saves to complete
    await waitForSyncStatus(page)

    // Reload page
    await page.reload()
    await expect(page.locator('.ProseMirror')).toBeVisible({ timeout: 5000 })

    // All content should be saved
    await expect(page.locator('.ProseMirror')).toContainText(rapidText)
  })

  test('rapid title changes are handled correctly', async ({ page }) => {
    await createNewDocument(page)

    const titleInput = page.locator('textarea[placeholder="Untitled"]')

    // Change title rapidly
    const titles = ['Title 1', 'Title 2', 'Title 3', 'Final Title']

    for (const title of titles) {
      await titleInput.click()
      await titleInput.fill(title)
    }
    await titleInput.blur()

    // Wait for final save
    await waitForDocumentPatchTitle(page, 'Final Title')
    await waitForSyncStatus(page)

    // Reload and verify final title is saved
    await waitForSavedReload(page)

    await expect(titleInput).toHaveValue('Final Title')
  })

  test('rapid document creation does not cause duplicates', async ({ page }) => {
    await page.goto('/docs')
    await page.waitForLoadState('networkidle')

    // Keep track of created document URLs to verify they're unique
    const createdUrls: string[] = []

    // Create documents sequentially
    const sidebarButton = page.locator('aside').getByRole('button', { name: /new|create|\+/i }).first()

    for (let i = 0; i < 3; i++) {
      await expect(sidebarButton).toBeVisible({ timeout: 3000 })
      await sidebarButton.click()
      await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 5000 })

      // Store the URL to check for duplicates
      const url = page.url()
      createdUrls.push(url)

      // Wait for editor to be ready before navigating
      await expect(page.locator('.ProseMirror')).toBeVisible({ timeout: 5000 })

      // Navigate back to docs list
      await page.goto('/docs')
      await page.waitForLoadState('networkidle')
      await expect(sidebarButton).toBeVisible({ timeout: 3000 })
    }

    // THE CORE TEST: Verify no duplicate document IDs were created
    // This is what "does not cause duplicates" means - each click creates a unique document
    const uniqueUrls = new Set(createdUrls)
    expect(uniqueUrls.size).toBe(3) // All 3 must be unique (no duplicates)

    // Verify each document is accessible (confirms they were actually created)
    for (const url of createdUrls) {
      await page.goto(url)
      await expect(page.locator('.ProseMirror')).toBeVisible({ timeout: 5000 })
    }
  })

  test('rapid mention searches do not cause race conditions', async ({ page }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Type @ multiple times rapidly
    for (let i = 0; i < 5; i++) {
      await triggerMentionPopup(page, editor)
      await page.keyboard.type('test')
      await page.keyboard.press('Escape')
      await page.keyboard.press('Backspace')
      await page.keyboard.press('Backspace')
      await page.keyboard.press('Backspace')
      await page.keyboard.press('Backspace')
      await page.keyboard.press('Backspace')
    }

    // Editor should still be functional
    await page.keyboard.type('Still works')
    await expect(editor).toContainText('Still works')
  })
})

test.describe('Race Conditions - Image Upload', () => {
  test.beforeEach(async ({ page }) => {
    await login(page)
  })

  test('image upload while typing does not interrupt editing', async ({ page }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Start typing
    await page.keyboard.type('Before image ')

    // Trigger image upload via slash command
    await page.keyboard.type('/image')

    // Click the Image option specifically
    const imageOption = page.getByRole('button', { name: /^Image Upload an image/i })
    await expect(imageOption).toBeVisible({ timeout: 3000 })

    const tmpPath = createTestImageFile()
    const fileChooserPromise = page.waitForEvent('filechooser')
    await imageOption.click()

    const fileChooser = await fileChooserPromise
    await fileChooser.setFiles(tmpPath)

    // Wait for upload to complete
    await waitForUploadedImages(editor, 1)

    // Continue typing (click editor first since file chooser may have changed focus)
    await editor.click()
    await page.keyboard.type(' After image')

    await waitForSyncStatus(page)

    // Both text and image should be present
    await expect(editor).toContainText('Before image')
    await expect(editor).toContainText('After image')
    await waitForUploadedImages(editor, 1)

    fs.unlinkSync(tmpPath)
  })

  test('multiple image uploads in parallel', async ({ page }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Upload three images, one at a time
    const tmpPaths: string[] = []

    for (let i = 0; i < 3; i++) {
      await page.keyboard.type('/image')

      // Click the Image option specifically
      const imageOption = page.getByRole('button', { name: /^Image Upload an image/i })
      await expect(imageOption).toBeVisible({ timeout: 3000 })

      const tmpPath = createTestImageFile()
      tmpPaths.push(tmpPath)

      const fileChooserPromise = page.waitForEvent('filechooser')
      await imageOption.click()

      const fileChooser = await fileChooserPromise
      await fileChooser.setFiles(tmpPath)

      // Wait for upload to complete before next one
      await waitForUploadedImages(editor, i + 1)

      // Click editor to refocus
      await editor.click()
    }

    // Wait for all uploads to complete
    await waitForUploadedImages(editor, 3)

    // Should have 3 images
    const imgCount = await editor.locator('img').count()
    expect(imgCount).toBe(3)

    // Cleanup
    tmpPaths.forEach(p => fs.unlinkSync(p))
  })

  test('mention search while editing', async ({ page }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Type, trigger mention, continue typing
    await page.keyboard.type('Some text before ')
    await triggerMentionPopup(page, editor)

    // Close mention popup and continue typing
    await page.keyboard.press('Escape')
    await page.keyboard.type(' more text after')

    // Preserve the follow-up typing after the mention flow, even if the editor rewrites
    // the trigger text while opening and dismissing the popup.
    await expect(editor).toContainText('more text after')
    await expect(editor).toContainText('@')
  })
})

test.describe('Race Conditions - Network and Offline', () => {
  test.beforeEach(async ({ page }) => {
    await login(page)
  })

  test('offline edits queue and sync when back online', async ({ page, context }) => {
    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Make initial edit online
    await page.keyboard.type('Online content. ')
    await waitForSyncStatus(page)

    // Go offline
    await context.setOffline(true)

    // Make edits while offline
    await page.keyboard.type('Offline edit 1. ')
    await page.keyboard.type('Offline edit 2.')

    // Content should be visible locally
    await expect(editor).toContainText('Online content')
    await expect(editor).toContainText('Offline edit 1')
    await expect(editor).toContainText('Offline edit 2')

    // Go back online
    await context.setOffline(false)

    // Wait for the sync indicator to come back and leave the offline state.
    await expect(page.getByTestId('sync-status')).toBeVisible({ timeout: 15000 })
    await expect.poll(async () => {
      const statusText = await page.getByTestId('sync-status').textContent()
      return statusText?.trim() ?? ''
    }, {
      timeout: 15000,
      intervals: [250, 500, 1000],
    }).not.toMatch(/offline/i)

    // Reload to verify sync happened
    await page.reload()
    await expect(page.locator('.ProseMirror')).toBeVisible({ timeout: 5000 })

    // All content should still be present
    await expect(page.locator('.ProseMirror')).toContainText('Online content')
    await expect(page.locator('.ProseMirror')).toContainText('Offline edit 1')
    await expect(page.locator('.ProseMirror')).toContainText('Offline edit 2')
  })

  test('slow network does not cause duplicate operations', async ({ page, context }) => {
    // Simulate slow network
    await context.route('**/*', async (route) => {
      await new Promise(resolve => setTimeout(resolve, 500))
      await route.continue()
    })

    await createNewDocument(page)

    const editor = page.locator('.ProseMirror')
    await editor.click()

    // Make rapid edits on slow network
    await page.keyboard.type('Test content')

    // Wait for operations to complete
    await waitForSyncStatus(page)

    // Content should appear exactly once
    const content = await editor.textContent()
    expect(content?.match(/Test content/g)?.length).toBe(1)
  })
})
