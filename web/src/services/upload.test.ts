import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  getMimeTypeFromExtension,
  isAllowedFileType,
  isImageFile,
  uploadDataUrl,
  uploadFile,
} from './upload';

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

describe('upload service', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    Object.defineProperty(File.prototype, 'arrayBuffer', {
      configurable: true,
      value: function arrayBuffer(this: File) {
        return Promise.resolve(new TextEncoder().encode(this.name).buffer);
      },
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('uploads through the local API flow and reports progress updates', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-token' }))
      .mockResolvedValueOnce(jsonResponse({
        fileId: 'file-1',
        uploadUrl: '/api/files/file-1/upload',
        s3Key: 'local/file-1',
      }))
      .mockResolvedValueOnce(jsonResponse({ ok: true }))
      .mockResolvedValueOnce(jsonResponse({ cdn_url: '/uploads/file-1.png' }));

    const onProgress = vi.fn();
    const file = new File(['hello'], 'design.png', { type: '' });

    const result = await uploadFile(file, onProgress);

    expect(result).toEqual({
      fileId: 'file-1',
      cdnUrl: '/uploads/file-1.png',
    });
    expect(String(fetchMock.mock.calls[1]?.[0])).toContain('/api/files/upload');
    expect(fetchMock.mock.calls[1]?.[1]).toEqual(expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({
        filename: 'design.png',
        mimeType: 'image/png',
        sizeBytes: file.size,
      }),
    }));
    expect(String(fetchMock.mock.calls[2]?.[0])).toContain('/api/files/file-1/upload');
    expect(fetchMock.mock.calls[2]?.[1]).toEqual(expect.objectContaining({
      method: 'POST',
      headers: expect.objectContaining({
        'Content-Type': 'image/png',
        'x-csrf-token': 'csrf-token',
      }),
    }));
    expect(onProgress.mock.calls.map(([progress]) => progress)).toEqual([
      { fileId: '', progress: 10, status: 'pending' },
      { fileId: 'file-1', progress: 20, status: 'pending' },
      { fileId: 'file-1', progress: 30, status: 'uploading' },
      { fileId: 'file-1', progress: 90, status: 'uploading' },
      { fileId: 'file-1', progress: 100, status: 'complete' },
    ]);
  });

  it('uploads directly to S3 and confirms the upload', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-token' }))
      .mockResolvedValueOnce(jsonResponse({
        fileId: 'file-2',
        uploadUrl: 'https://uploads.example.com/file-2',
        s3Key: 'prod/file-2',
      }))
      .mockResolvedValueOnce(new Response(null, { status: 200 }))
      .mockResolvedValueOnce(jsonResponse({ cdnUrl: 'https://cdn.example.com/file-2.png' }));

    const onProgress = vi.fn();
    const file = new File(['hello'], 'diagram.png', { type: 'image/png' });

    const result = await uploadFile(file, onProgress);

    expect(result).toEqual({
      fileId: 'file-2',
      cdnUrl: 'https://cdn.example.com/file-2.png',
    });
    expect(fetchMock).toHaveBeenNthCalledWith(3, 'https://uploads.example.com/file-2', expect.objectContaining({
      method: 'PUT',
      headers: { 'Content-Type': 'image/png' },
    }));
    expect(String(fetchMock.mock.calls[3]?.[0])).toContain('/api/files/file-2/confirm');
    expect(fetchMock.mock.calls[3]?.[1]).toEqual(expect.objectContaining({
      method: 'POST',
      headers: { 'x-csrf-token': 'csrf-token' },
    }));
    expect(onProgress).toHaveBeenLastCalledWith({
      fileId: 'file-2',
      progress: 100,
      status: 'complete',
    });
  });

  it('surfaces API creation failures and marks progress as errored', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-token' }))
      .mockResolvedValueOnce(jsonResponse({ error: 'Upload blocked' }, 400));

    const onProgress = vi.fn();

    await expect(
      uploadFile(new File(['hello'], 'blocked.exe', { type: '' }), onProgress)
    ).rejects.toThrow('Upload blocked');

    expect(onProgress).toHaveBeenLastCalledWith({
      fileId: '',
      progress: 10,
      status: 'error',
      error: 'Upload blocked',
    });
  });

  it('converts data URLs into files before uploading', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(new Response(new Blob(['data'], { type: 'image/png' }), {
        status: 200,
        headers: { 'content-type': 'image/png' },
      }))
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-token' }))
      .mockResolvedValueOnce(jsonResponse({
        fileId: 'file-3',
        uploadUrl: '/api/files/file-3/upload',
        s3Key: 'local/file-3',
      }))
      .mockResolvedValueOnce(jsonResponse({ ok: true }))
      .mockResolvedValueOnce(jsonResponse({ cdn_url: '/uploads/file-3.png' }));

    const result = await uploadDataUrl('data:image/png;base64,AAAA', 'clipboard.png');

    expect(result).toEqual({
      fileId: 'file-3',
      cdnUrl: '/uploads/file-3.png',
    });
    expect(fetchMock).toHaveBeenCalledWith('data:image/png;base64,AAAA');
  });

  it('rejects aborted uploads before any network calls', async () => {
    const controller = new AbortController();
    controller.abort();

    await expect(
      uploadFile(new File(['hello'], 'cancelled.png', { type: 'image/png' }), undefined, controller.signal)
    ).rejects.toMatchObject({ name: 'AbortError' });

    expect(fetch).not.toHaveBeenCalled();
  });

  it('covers file-type helper behavior', () => {
    expect(getMimeTypeFromExtension('brief.DOCX')).toBe(
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    );
    expect(getMimeTypeFromExtension('archive.unknown')).toBeNull();
    expect(isAllowedFileType('application/javascript', 'script.js')).toBe(false);
    expect(isAllowedFileType('application/pdf', 'report.pdf')).toBe(true);
    expect(isAllowedFileType('text/plain')).toBe(true);
    expect(isImageFile('image/webp')).toBe(true);
    expect(isImageFile('application/pdf')).toBe(false);
  });
});
