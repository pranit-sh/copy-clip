// Web implementation of [WebBridge].
//
// The Chrome extension's background script captures the selection via the
// context menu, then the popup forwards it to the Flutter app by calling
// `window.copyClipReceiveSelection(text)` — which we register here from Dart.

import 'dart:js_interop';

typedef SelectionHandler = void Function(String selection);

@JS('window')
external JSObject get _window;

class WebBridge {
  static SelectionHandler? onSelectionCaptured;

  static void init() {
    try {
      final handler = ((JSString jsText) {
        final text = jsText.toDart;
        if (text.isEmpty) return;
        onSelectionCaptured?.call(text);
      }).toJS;
      _window['copyClipReceiveSelection'.toJS] = handler;
    } catch (_) {
      // Extension shell not present — ignore.
    }
  }
}

extension on JSObject {
  external void operator []=(JSString key, JSAny? value);
}
