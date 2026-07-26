// Chrome extension background service worker.
// Registers a context menu item so users can right-click selected text on
// any page and save it directly to Copy Clip.

const MENU_ID = 'copy_clip_save_selection';
const STORAGE_KEY = 'pendingSelection';

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: MENU_ID,
    title: 'Save selection to Copy Clip',
    contexts: ['selection'],
  });
});

chrome.contextMenus.onClicked.addListener((info) => {
  if (info.menuItemId !== MENU_ID) return;
  const text = (info.selectionText || '').trim();
  if (!text) return;
  // Stash the text; the popup will pick it up next time it opens.
  chrome.storage.local.set({ [STORAGE_KEY]: { text, at: Date.now() } });
  // Also open the popup right away so the user gets immediate feedback.
  if (chrome.action && chrome.action.openPopup) {
    chrome.action.openPopup().catch(() => {});
  }
});
