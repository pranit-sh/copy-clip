// @ts-nocheck
/* eslint-disable */
//
// Custom Flutter bootstrap.
//
// NOTE FOR READERS: this file is a Flutter template, not standalone JS.
// It contains double-brace substitution tokens that the Flutter web build
// replaces with real JavaScript before emitting to build/web/. Do NOT
// mention those tokens inside comments — the templater does a naive text
// replacement and would inject code into the middle of the comment,
// producing runtime SyntaxErrors like "Unexpected identifier". The tokens
// are only safe on their own lines (or in expression position).
//
// When Flutter finds this file in `web/`, it uses it verbatim instead of
// generating one. That lets us control how the loader starts up.
//
// Why we need this:
// Inside a Chrome MV3 extension popup, calling
// navigator.serviceWorker.register(...) throws a DOMException — extension
// pages cannot own a page-level service worker (the extension already has
// its own background service worker declared in manifest.json). Flutter's
// default bootstrap unconditionally registers flutter_service_worker.js,
// which surfaces as:
//   "Exception while loading service worker: [object DOMException]"
//
// We detect the extension context and simply omit `serviceWorkerSettings`
// in that case. Regular web builds still get the service worker.

{{flutter_js}}
{{flutter_build_config}}

(function () {
  var isChromeExtension =
    typeof window !== 'undefined' &&
    typeof window.chrome !== 'undefined' &&
    !!window.chrome.runtime &&
    !!window.chrome.runtime.id;

  var loadOptions = {};
  if (!isChromeExtension) {
    loadOptions.serviceWorkerSettings = {
      serviceWorkerVersion: {{flutter_service_worker_version}}
    };
  }

  _flutter.loader.load(loadOptions);
})();
