// Stubbed js_util file for platforms where dart:js_util is unavailable.
// Only web should use the real dart:js_util implementation.

T getProperty<T>(Object? o, Object? propertyName) => throw UnsupportedError('dart:js_util is not supported on this platform.');
T callMethod<T>(Object? o, Object? methodName, List<Object?> args) => throw UnsupportedError('dart:js_util is not supported on this platform.');
Future<T> promiseToFuture<T>(Object jsPromise) => throw UnsupportedError('dart:js_util is not supported on this platform.');
final Object globalThis = Object();
