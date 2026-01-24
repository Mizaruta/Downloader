import 'dart:developer' as developer;

class LoggerService {
  static void i(String message, [String? name]) {
    // print('ℹ️ [${name ?? 'INFO'}] $message');
    developer.log(message, name: name ?? 'INFO', level: 800);
  }

  static void w(String message, [String? name]) {
    // print('⚠️ [${name ?? 'WARN'}] $message');
    developer.log(message, name: name ?? 'WARN', level: 900);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    // print('❌ [ERROR] $message');
    // if (stackTrace != null) print(stackTrace);
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void debug(String message) {
    // print('🐞 [DEBUG] $message');
    developer.log(message, name: 'DEBUG', level: 500);
  }
}
