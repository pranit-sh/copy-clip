// Public entry point — delegates to the platform-specific implementation.
export 'web_bridge_stub.dart'
    if (dart.library.js_interop) 'web_bridge_web.dart';
