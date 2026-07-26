// Runs inside the popup before Flutter boots.
// If the background script stashed a "save selection" payload, forward it to
// Flutter once the app has registered its receiver.

(function () {
  const STORAGE_KEY = 'pendingSelection';

  // Only meaningful when running as a Chrome extension.
  if (typeof chrome === 'undefined' || !chrome.storage) return;

  // Lock the viewport to popup dimensions when we're inside the extension.
  document.documentElement.classList.add('is-popup');

  chrome.storage.local.get([STORAGE_KEY], (data) => {
    const payload = data && data[STORAGE_KEY];
    if (!payload || !payload.text) return;

    // Wait for Flutter to register the receiver, then hand off.
    const start = Date.now();
    const tick = () => {
      if (typeof window.copyClipReceiveSelection === 'function') {
        try {
          window.copyClipReceiveSelection(payload.text);
        } finally {
          chrome.storage.local.remove(STORAGE_KEY);
        }
        return;
      }
      // Give up after 8s.
      if (Date.now() - start > 8000) return;
      setTimeout(tick, 120);
    };
    tick();
  });
})();
