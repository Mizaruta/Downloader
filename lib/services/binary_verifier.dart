import 'dart:io';
import '../core/logger/logger_service.dart';

class BinaryVerifier {
  /// Checks if yt-dlp is installed and returns version info
  static Future<BinaryStatus> checkYtDlp() async {
    return _checkBinary('yt-dlp', ['--version']);
  }

  /// Checks if ffmpeg is installed and returns version info
  static Future<BinaryStatus> checkFfmpeg() async {
    return _checkBinary('ffmpeg', ['-version']);
  }

  static Future<BinaryStatus> _checkBinary(
    String name,
    List<String> args,
  ) async {
    try {
      final result = await Process.run(name, args, runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        // Extract first line for version
        final version = output.split('\n').first.trim();
        LoggerService.i('$name check passed: $version');
        return BinaryStatus(isInstalled: true, version: version, error: null);
      } else {
        return BinaryStatus(
          isInstalled: false,
          version: null,
          error: result.stderr.toString(),
        );
      }
    } catch (e) {
      LoggerService.e('$name check failed: $e');
      return BinaryStatus(
        isInstalled: false,
        version: null,
        error: e.toString(),
      );
    }
  }
}

class BinaryStatus {
  final bool isInstalled;
  final String? version;
  final String? error;

  BinaryStatus({required this.isInstalled, this.version, this.error});
}
