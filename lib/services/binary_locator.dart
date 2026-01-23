import 'dart:io';
import '../core/logger/logger_service.dart';

class BinaryLocator {
  static const String ytDlpName = 'yt-dlp';
  static const String ffmpegName = 'ffmpeg';
  static const String hitomiName = 'Hitomi Downloader';

  // Custom paths can be set from settings
  String? _customHitomiPath;

  void setHitomiPath(String? path) {
    _customHitomiPath = path;
    LoggerService.i('Hitomi path set to: $path');
  }

  Future<String?> findYtDlp() async {
    return _findBinary(ytDlpName);
  }

  Future<String?> findFfmpeg() async {
    return _findBinary(ffmpegName);
  }

  /// Find Hitomi-Downloader executable
  /// Checks custom path first, then common locations
  Future<String?> findHitomi() async {
    // 1. Try custom path if set
    if (_customHitomiPath != null && _customHitomiPath!.isNotEmpty) {
      final file = File(_customHitomiPath!);
      if (await file.exists()) {
        LoggerService.i('Found Hitomi at custom path: $_customHitomiPath');
        return _customHitomiPath;
      }
    }

    // 2. Try common locations on Windows
    final commonPaths = [
      r'C:\Program Files\Hitomi Downloader\Hitomi Downloader.exe',
      r'C:\Program Files (x86)\Hitomi Downloader\Hitomi Downloader.exe',
      'Hitomi Downloader.exe', // Current directory
    ];

    // Also check user's Downloads folder
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      commonPaths.add('$userProfile\\Downloads\\Hitomi Downloader.exe');
      commonPaths.add('$userProfile\\Desktop\\Hitomi Downloader.exe');
    }

    for (final path in commonPaths) {
      final file = File(path);
      if (await file.exists()) {
        LoggerService.i('Found Hitomi at: $path');
        return path;
      }
    }

    LoggerService.w('Hitomi Downloader not found');
    return null;
  }

  Future<String?> _findBinary(String binaryName) async {
    // On Windows, just return the name and let the shell resolve it from PATH
    // when we run with runInShell: true
    if (Platform.isWindows) {
      // Test if it's available
      try {
        final result = await Process.run(binaryName, [
          '--version',
        ], runInShell: true);
        if (result.exitCode == 0) {
          LoggerService.i('Found $binaryName in PATH (via shell)');
          return binaryName; // Just return the name, shell will resolve
        }
      } catch (e) {
        LoggerService.w('$binaryName not found via shell: $e');
      }
    }

    // Fallback: Try 'where' command on Windows
    try {
      final result = await Process.run('where', [binaryName], runInShell: true);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().split('\n').first.trim();
        if (path.isNotEmpty) {
          LoggerService.i('Found $binaryName at: $path');
          return path;
        }
      }
    } catch (e) {
      LoggerService.w('Could not locate $binaryName: $e');
    }

    LoggerService.e('$binaryName not found');
    return null;
  }
}
