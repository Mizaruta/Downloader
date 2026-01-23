import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/download_request.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../services/binary_locator.dart';

/// Source for downloading via Hitomi-Downloader CLI
/// Used as fallback when yt-dlp fails for certain sites
class HitomiSource {
  final BinaryLocator _binaryLocator;

  HitomiSource(this._binaryLocator);

  final _activeProcesses = <String, Process>{};

  /// Sites that Hitomi-Downloader handles better than yt-dlp
  static const supportedDomains = [
    'twitter.com',
    'x.com',
    'pornhub.com',
    'xvideos.com',
    'xnxx.com',
    'spankbang.com',
    'xhamster.com',
    'redtube.com',
    'tiktok.com',
    'instagram.com',
  ];

  /// Check if this URL should try Hitomi as fallback
  static bool shouldUseFallback(String url) {
    return supportedDomains.any((domain) => url.contains(domain));
  }

  /// Download using Hitomi-Downloader CLI
  /// Returns a stream of progress events
  Stream<HitomiProgressEvent> download(
    String id,
    DownloadRequest request,
  ) async* {
    LoggerService.i(
      'HitomiSource: Starting fallback download for ${request.url}',
    );

    final hitomiPath = await _binaryLocator.findHitomi();
    if (hitomiPath == null) {
      throw Exception(
        'Hitomi Downloader not found. Please download it from '
        'https://github.com/KurtBestor/Hitomi-Downloader/releases '
        'and set the path in Settings.',
      );
    }

    // Build command arguments
    // Hitomi CLI format: "Hitomi Downloader.exe" --url "URL" --dir "OUTPUT_DIR"
    final args = <String>[];

    args.add('--url');
    args.add(request.url);

    // Output directory
    if (request.outputFolder != null && request.outputFolder!.isNotEmpty) {
      args.add('--dir');
      args.add(request.outputFolder!);
    }

    LoggerService.i('HitomiSource: Running $hitomiPath ${args.join(' ')}');

    try {
      final process = await Process.start(hitomiPath, args, runInShell: true);
      _activeProcesses[id] = process;

      // Buffer for output
      final outputBuffer = StringBuffer();

      // Listen to stdout for progress
      process.stdout.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);
        LoggerService.debug('Hitomi stdout: $data');
      });

      // Listen to stderr for errors/warnings
      process.stderr.transform(utf8.decoder).listen((data) {
        LoggerService.w('Hitomi stderr: $data');
      });

      // Since Hitomi doesn't have structured progress output,
      // we just yield periodic updates while waiting
      int tickCount = 0;
      while (_activeProcesses.containsKey(id)) {
        await Future.delayed(const Duration(milliseconds: 500));
        tickCount++;

        // Simulate progress (Hitomi doesn't report percentage via CLI)
        // We estimate based on time, real progress would need log parsing
        yield HitomiProgressEvent(
          status: 'Downloading...',
          isComplete: false,
          elapsedSeconds: tickCount ~/ 2,
        );

        // Check if process has exited
        final exitCode = await process.exitCode.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => -1,
        );

        if (exitCode != -1) {
          _activeProcesses.remove(id);

          if (exitCode == 0) {
            LoggerService.i('HitomiSource: Download completed!');
            yield HitomiProgressEvent(
              status: 'Completed',
              isComplete: true,
              elapsedSeconds: tickCount ~/ 2,
            );
          } else {
            throw Exception('Hitomi exited with code $exitCode');
          }
          break;
        }
      }
    } catch (e, stack) {
      LoggerService.e('HitomiSource error', e, stack);
      _activeProcesses.remove(id);
      rethrow;
    }
  }

  /// Cancel ongoing download
  Future<void> cancel(String id) async {
    final process = _activeProcesses[id];
    if (process != null) {
      LoggerService.i('HitomiSource: Canceling download $id');
      process.kill();
      _activeProcesses.remove(id);
    }
  }
}

class HitomiProgressEvent {
  final String status;
  final bool isComplete;
  final int elapsedSeconds;

  HitomiProgressEvent({
    required this.status,
    required this.isComplete,
    required this.elapsedSeconds,
  });
}
