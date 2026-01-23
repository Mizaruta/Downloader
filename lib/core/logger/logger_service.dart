import 'dart:developer' as developer;

class LoggerService {
  static void i(String message, [String? name]) {
    final formatted = 'ℹ️ [${name ?? 'INFO'}] $message';
    print(formatted); // Console output
    developer.log(formatted, name: name ?? 'INFO');
  }

  static void w(String message, [String? name]) {
    final formatted = '⚠️ [${name ?? 'WARN'}] $message';
    print(formatted); // Console output
    developer.log(formatted, name: name ?? 'WARN');
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    final formatted = '❌ [ERROR] $message ${error != null ? '| $error' : ''}';
    print(formatted); // Console output
    if (stackTrace != null) print(stackTrace);
    developer.log(
      formatted,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message) {
    final formatted = '🐞 [DEBUG] $message';
    print(formatted); // Console output
    developer.log(formatted, name: 'DEBUG');
  }
}
