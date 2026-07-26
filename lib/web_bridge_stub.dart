// Non-web stub — WebBridge is a no-op off the browser.

typedef SelectionHandler = void Function(String selection);

class WebBridge {
  static SelectionHandler? onSelectionCaptured;
  static void init() {}
}
