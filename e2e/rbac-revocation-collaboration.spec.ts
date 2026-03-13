import { expect, test, type Page } from './fixtures/isolated-env';
import type { APIRequestContext, Browser, BrowserContext } from '@playwright/test';
import {
  waitForEditorReady,
  waitForSavedReload,
  waitForSyncStatus,
  waitForUrlChangeAway,
} from './fixtures/test-helpers';

async function createUserContext(browser: Browser): Promise<BrowserContext> {
  const context = await browser.newContext();
  await context.addInitScript(() => {
    localStorage.setItem('ship:disableActionItemsModal', 'true');
  });
  return context;
}

async function login(page: Page, email: string, password = 'admin123') {
  await page.goto('/login');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL(/\/login($|\?)/, { timeout: 5000 });
}

async function createSharedDocument(page: Page): Promise<string> {
  await page.goto('/docs');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: /new document/i }).first().click();
  await page.waitForURL(/\/documents\/[a-f0-9-]+/, { timeout: 10000 });
  await waitForEditorReady(page);

  await page.locator('textarea[placeholder="Untitled"]').fill('RBAC Revocation Active Collaboration');
  await page.locator('.ProseMirror').click();
  await page.keyboard.type('Admin-owned baseline');
  await waitForSyncStatus(page);

  return page.url();
}

async function removeMemberFromWorkspace(adminRequest: APIRequestContext, memberEmail: string): Promise<void> {
  const meResponse = await adminRequest.get('/api/auth/me');
  expect(meResponse.ok(), 'Admin session should expose current workspace').toBeTruthy();
  const mePayload = await meResponse.json();
  const workspaceId = mePayload?.data?.currentWorkspace?.id as string | undefined;
  expect(workspaceId, 'Admin session should have an active workspace').toBeTruthy();

  const membersResponse = await adminRequest.get(`/api/admin/workspaces/${workspaceId}/members`);
  expect(membersResponse.ok(), 'Admin should be able to list workspace members').toBeTruthy();
  const membersPayload = await membersResponse.json();
  const member = (membersPayload?.data?.members as Array<{ userId: string; email: string }> | undefined)
    ?.find(entry => entry.email.toLowerCase() === memberEmail.toLowerCase());
  expect(member, `Seed data should include workspace member ${memberEmail}`).toBeTruthy();

  const csrfResponse = await adminRequest.get('/api/csrf-token');
  expect(csrfResponse.ok(), 'Admin session should be able to fetch a CSRF token').toBeTruthy();
  const csrfPayload = await csrfResponse.json();
  const token = csrfPayload?.token as string | undefined;
  expect(token, 'CSRF token response should include a token').toBeTruthy();

  const removeResponse = await adminRequest.delete(`/api/admin/workspaces/${workspaceId}/members/${member!.userId}`, {
    headers: {
      'X-CSRF-Token': token!,
    },
  });
  expect(removeResponse.ok(), 'Admin should be able to revoke workspace membership').toBeTruthy();
}

test('revoking workspace access disconnects the active collaborator before more edits can sync', async ({ browser }) => {
  const adminContext = await createUserContext(browser);
  const memberContext = await createUserContext(browser);
  const adminPage = await adminContext.newPage();
  const memberPage = await memberContext.newPage();

  try {
    await login(adminPage, 'dev@ship.local');
    await login(memberPage, 'alice.chen@ship.local');

    const docUrl = await createSharedDocument(adminPage);
    await waitForSavedReload(adminPage);
    await waitForEditorReady(adminPage);
    await memberPage.goto(docUrl);
    await waitForEditorReady(memberPage);
    await waitForSyncStatus(memberPage);

    memberPage.on('dialog', async dialog => {
      await dialog.accept();
    });

    await removeMemberFromWorkspace(adminPage.request, 'alice.chen@ship.local');

    const documentId = docUrl.match(/\/documents\/([a-f0-9-]+)/)?.[1];
    expect(documentId, 'Expected document URL to include an ID').toBeTruthy();
    const deniedRead = await memberPage.request.get(`/api/documents/${documentId}`);
    expect([401, 403, 404]).toContain(deniedRead.status());

    const unauthorizedMarker = 'Unauthorized edit after revocation';
    const deniedWrite = await memberPage.request.patch(`/api/documents/${documentId}/content`, {
      data: {
        content: {
          type: 'doc',
          content: [
            {
              type: 'paragraph',
              content: [{ type: 'text', text: unauthorizedMarker }],
            },
          ],
        },
      },
    });
    expect([401, 403, 404]).toContain(deniedWrite.status());

    await memberPage.reload();
    await waitForUrlChangeAway(memberPage, docUrl);
    await expect(memberPage.locator('.ProseMirror')).toHaveCount(0);

    const adminRead = await adminPage.request.get(`/api/documents/${documentId}`);
    expect(adminRead.ok(), 'Admin should still be able to read the document after revocation').toBeTruthy();
  } finally {
    await adminContext.close().catch(() => {});
    await memberContext.close().catch(() => {});
  }
});
