import 'dart:async';
import '../logger/logger_service.dart';

/// Types of errors that can occur in the application.
enum AppErrorType { network, diskSpace, process, permission, unknown }

/// Structured application error.
class AppError {
  final AppErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;

  AppError({required this.type, required this.message, this.details})
    : timestamp = DateTime.now();

  String get displayMessage {
    switch (type) {
      case AppErrorType.network:
        return '🌐 Network Error: $message';
      case AppErrorType.diskSpace:
        return '💾 Disk Space: $message';
      case AppErrorType.process:
        return '⚙️ Process Error: $message';
      case AppErrorType.permission:
        return '🔒 Permission Error: $message';
      case AppErrorType.unknown:
        return '❌ Error: $message';
    }
  }

  @override
  String toString() => '$type: $message${details != null ? ' ($details)' : ''}';
}

/// Centralized error handling service.
/// Emits errors to a stream for UI consumption (toasts, snackbars).
class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();

  factory ErrorHandlingService() => _instance;

  ErrorHandlingService._internal();

  final _controller = StreamController<AppError>.broadcast();

  /// Stream of application errors for the UI to listen to.
  Stream<AppError> get errorStream => _controller.stream;

  /// Last N errors for display in a log viewer.
  final List<AppError> _recentErrors = [];
  List<AppError> get recentErrors => List.unmodifiable(_recentErrors);

  /// Report an error. Logs it and emits to the stream.
  void report(AppError error) {
    LoggerService.e('AppError: ${error.type} — ${error.message}');
    _recentErrors.add(error);
    if (_recentErrors.length > 50) {
      _recentErrors.removeAt(0);
    }
    _controller.add(error);
  }

  /// Convenience: report a network error.
  void reportNetwork(String message, [String? details]) {
    report(
      AppError(type: AppErrorType.network, message: message, details: details),
    );
  }

  /// Convenience: report a process error.
  void reportProcess(String message, [String? details]) {
    report(
      AppError(type: AppErrorType.process, message: message, details: details),
    );
  }

  /// Convenience: report a disk space error.
  void reportDiskSpace(String message, [String? details]) {
    report(
      AppError(
        type: AppErrorType.diskSpace,
        message: message,
        details: details,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
