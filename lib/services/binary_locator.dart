import 'dart:io';
import '../core/logger/logger_service.dart';

class BinaryLocator {
  static const String ytDlpName = 'yt-dlp';
  static const String ffmpegName = 'ffmpeg';
  static const String galleryDlName = 'gallery-dl';

  // Custom paths can be set from settings
  String? _customGalleryDlPath;

  void setGalleryDlPath(String? path) {
    _customGalleryDlPath = path;
    LoggerService.i('gallery-dl path set to: $path');
  }

  Future<String?> findYtDlp() async {
    return _findBinary(ytDlpName);
  }

  Future<String?> findFfmpeg() async {
    return _findBinary(ffmpegName);
  }

  Future<String?> findAria2c() async {
    return _findBinary('aria2c');
  }

  /// Find gallery-dl executable
  /// Checks custom path first, then PATH, then common pip locations
  Future<String?> findGalleryDl() async {
    // 1. Try custom path if set
    if (_customGalleryDlPath != null && _customGalleryDlPath!.isNotEmpty) {
      final file = File(_customGalleryDlPath!);
      if (await file.exists()) {
        LoggerService.i(
          'Found gallery-dl at custom path: $_customGalleryDlPath',
        );
        return _customGalleryDlPath;
      }
    }

    // 2. Try via PATH (pip install --user adds to Scripts)
    try {
      final result = await Process.run(galleryDlName, [
        '--version',
      ], runInShell: true);
      if (result.exitCode == 0) {
        LoggerService.i('Found gallery-dl in PATH');
        return galleryDlName;
      }
    } catch (e) {
      LoggerService.w('gallery-dl not in PATH: $e');
    }

    // 3. Try common pip install locations on Windows
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final commonPaths = [
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python314\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python310\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python39\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Roaming\\Python\\Python314\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Roaming\\Python\\Python311\\Scripts\\gallery-dl.exe',
        '$userProfile\\AppData\\Roaming\\Python\\Python310\\Scripts\\gallery-dl.exe',
      ];

      for (final path in commonPaths) {
        final file = File(path);
        if (await file.exists()) {
          LoggerService.i('Found gallery-dl at: $path');
          return path;
        }
      }
    }

    LoggerService.w('gallery-dl not found');
    return null;
  }

  Future<String?> _findBinary(String binaryName) async {
    final versionArg = binaryName.contains('ffmpeg') ? '-version' : '--version';

    // 0. Check local bin folder first
    final binaryWithExt = binaryName.endsWith('.exe')
        ? binaryName
        : '$binaryName.exe';
    final localBinPath = '${Directory.current.path}\\bin\\$binaryWithExt';

    if (await File(localBinPath).exists()) {
      LoggerService.i('Checking if local bin $binaryName is valid...');
      if (await _verifyBinary(localBinPath, versionArg)) {
        LoggerService.i('Found valid $binaryName in local bin: $localBinPath');
        return localBinPath;
      } else {
        LoggerService.w('Local bin $binaryName is invalid or a broken stub.');
      }
    }

    // 1. Try via shell/PATH
    if (Platform.isWindows) {
      if (await _verifyBinary(binaryName, versionArg)) {
        LoggerService.i('Found valid $binaryName in PATH');
        return binaryName;
      }
    }

    // 2. Fallback: Try 'where' command to get full path from PATH
    try {
      final result = await Process.run('where', [binaryName], runInShell: true);
      if (result.exitCode == 0) {
        final paths = result.stdout.toString().split('\r\n');
        for (var path in paths) {
          path = path.trim();
          if (path.isNotEmpty && await _verifyBinary(path, versionArg)) {
            LoggerService.i('Found valid $binaryName via where: $path');
            return path;
          }
        }
      }
    } catch (e) {
      LoggerService.w('Could not locate $binaryName via where: $e');
    }

    LoggerService.e('$binaryName not found or all locations are invalid');
    return null;
  }

  Future<bool> _verifyBinary(String path, String versionArg) async {
    try {
      final result = await Process.run(path, [versionArg], runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
