// Conditional export for js_util so web-only imports do not break analysis on native targets.
export 'js_util_stub.dart' if (dart.library.js_util) 'dart:js_util';
