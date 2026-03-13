import { waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/services/upload', () => ({
  uploadFile: vi.fn(),
  isImageFile: vi.fn((mimeType: string) => mimeType.startsWith('image/')),
}));

vi.mock('@/services/uploadTracker', () => ({
  registerUpload: vi.fn(),
  updateUploadProgress: vi.fn(),
  unregisterUpload: vi.fn(),
}));

import { triggerImageUpload } from './ImageUpload';
import { uploadFile } from '@/services/upload';
import {
  registerUpload,
  unregisterUpload,
  updateUploadProgress,
} from '@/services/uploadTracker';

class MockFileReader {
  result: string | ArrayBuffer | null = 'data:image/png;base64,preview';
  onload: null | (() => void) = null;
  onerror: null | ((error: unknown) => void) = null;

  readAsDataURL(): void {
    queueMicrotask(() => {
      this.onload?.();
    });
  }
}

function createEditor() {
  const run = vi.fn();
  const insertContent = vi.fn(() => ({ run }));
  const focus = vi.fn(() => ({ insertContent, run }));
  const setNodeMarkup = vi.fn(() => 'transaction');
  const dispatch = vi.fn();

  return {
    chain: vi.fn(() => ({ focus, insertContent, run })),
    state: {
      doc: {
        descendants: (callback: (node: any, pos: number) => boolean | void) => {
          callback({
            type: { name: 'image' },
            attrs: { src: 'data:image/png;base64,preview' },
          }, 4);
        },
        nodeAt: vi.fn(() => ({
          attrs: {
            src: 'data:image/png;base64,preview',
            alt: 'clipboard.png',
            title: 'clipboard.png',
          },
        })),
      },
      tr: {
        setNodeMarkup,
      },
    },
    view: {
      dispatch,
    },
    __spies: {
      focus,
      insertContent,
      run,
      setNodeMarkup,
      dispatch,
    },
  };
}

describe('triggerImageUpload', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal('FileReader', MockFileReader);
    vi.stubGlobal('crypto', { randomUUID: vi.fn(() => 'upload-1') });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('uploads selected files, updates the editor, and notifies callbacks', async () => {
    vi.mocked(uploadFile).mockImplementation(async (_file, onProgress) => {
      onProgress?.({
        fileId: 'file-1',
        progress: 55,
        status: 'uploading',
      });
      return {
        fileId: 'file-1',
        cdnUrl: 'https://cdn.example.com/clipboard.png',
      };
    });

    const editor = createEditor();
    const onUploadStart = vi.fn();
    const onUploadComplete = vi.fn();
    const originalCreateElement = document.createElement.bind(document);
    const input = originalCreateElement('input');
    vi.spyOn(document, 'createElement').mockImplementation((tagName: string) =>
      tagName === 'input' ? input : originalCreateElement(tagName)
    );

    const file = new File(['image'], 'clipboard.png', { type: 'image/png' });
    Object.defineProperty(input, 'files', {
      configurable: true,
      value: [file],
    });

    triggerImageUpload(editor as any, { onUploadStart, onUploadComplete });
    input.onchange?.(new Event('change'));
    await waitFor(() => {
      expect(unregisterUpload).toHaveBeenCalledWith('upload-1');
    });

    expect(registerUpload).toHaveBeenCalledWith('upload-1', 'clipboard.png');
    expect(updateUploadProgress).toHaveBeenCalledWith('upload-1', 55);
    expect(unregisterUpload).toHaveBeenCalledWith('upload-1');
    expect(onUploadStart).toHaveBeenCalledWith(file);
    expect(onUploadComplete).toHaveBeenCalledWith('https://cdn.example.com/clipboard.png');
    expect(editor.__spies.insertContent).toHaveBeenCalledWith([
      {
        type: 'image',
        attrs: {
          src: 'data:image/png;base64,preview',
          alt: 'clipboard.png',
          title: 'clipboard.png',
        },
      },
      {
        type: 'paragraph',
      },
    ]);
    expect(editor.__spies.setNodeMarkup).toHaveBeenCalledWith(4, undefined, {
      src: 'https://cdn.example.com/clipboard.png',
      alt: 'clipboard.png',
      title: 'clipboard.png',
    });
    expect(editor.__spies.dispatch).toHaveBeenCalledWith('transaction');
  });

  it('returns early when navigation has already aborted the upload flow', () => {
    const originalCreateElement = document.createElement.bind(document);
    const createElementSpy = vi
      .spyOn(document, 'createElement')
      .mockImplementation((tagName: string) => originalCreateElement(tagName));
    const controller = new AbortController();
    controller.abort();

    triggerImageUpload(createEditor() as any, { abortController: controller });

    expect(createElementSpy).not.toHaveBeenCalled();
    expect(uploadFile).not.toHaveBeenCalled();
  });

  it('reports upload failures through the configured callback', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    vi.mocked(uploadFile).mockRejectedValue(new Error('Upload exploded'));

    const editor = createEditor();
    const onUploadError = vi.fn();
    const originalCreateElement = document.createElement.bind(document);
    const input = originalCreateElement('input');
    vi.spyOn(document, 'createElement').mockImplementation((tagName: string) =>
      tagName === 'input' ? input : originalCreateElement(tagName)
    );

    Object.defineProperty(input, 'files', {
      configurable: true,
      value: [new File(['image'], 'broken.png', { type: 'image/png' })],
    });

    triggerImageUpload(editor as any, { onUploadError });
    input.onchange?.(new Event('change'));
    await waitFor(() => {
      expect(onUploadError).toHaveBeenCalled();
    });

    expect(unregisterUpload).toHaveBeenCalledWith('upload-1');
    expect(onUploadError).toHaveBeenCalledWith(expect.objectContaining({
      message: 'Upload exploded',
    }));
    expect(consoleErrorSpy).toHaveBeenCalled();
  });
});
