import 'dart:convert';
import 'dart:io';
import '../../../../core/logger/logger_service.dart';
import '../../../../services/binary_locator.dart';
import '../../../../services/process_runner.dart';
import '../../domain/entities/grabbed_video.dart';

class LinkGrabberService {
  final BinaryLocator _binaryLocator;
  final ProcessRunner _processRunner;

  LinkGrabberService(this._binaryLocator, this._processRunner);

  Stream<GrabbedVideo> extractPlaylistMetadataStream(
    String url, {
    bool deepScan = false,
  }) async* {
    final ytDlpPath = await _binaryLocator.findYtDlp();
    if (ytDlpPath == null) {
      LoggerService.e('yt-dlp not found for link grabber');
      throw Exception('yt-dlp executable not found');
    }

    final List<String> args = [
      '--dump-json',
      '--skip-download',
      '--no-warnings',
      '--no-check-certificates',
    ];

    if (!deepScan) {
      args.add('--flat-playlist');
    }

    args.add(url);

    final process = await Process.start(
      ytDlpPath,
      args,
      environment: {'PYTHONIOENCODING': 'utf-8'},
    );

    final lineStream = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (line.trim().isEmpty) continue;

      try {
        final jsonOutput = jsonDecode(line);
        if (jsonOutput is Map<String, dynamic>) {
          yield GrabbedVideo.fromJson(jsonOutput);
        } else if (jsonOutput is Map) {
          yield GrabbedVideo.fromJson(Map<String, dynamic>.from(jsonOutput));
        }
      } catch (e) {
        LoggerService.e('Failed to parse line from yt-dlp: $line', e);
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final error = await process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .join();
      LoggerService.e(
        'yt-dlp link grabber failed with exit code $exitCode: $error',
      );
      throw Exception('yt-dlp error: $error');
    }
  }

  Future<int> getPlaylistCount(String url) async {
    final ytDlpPath = await _binaryLocator.findYtDlp();
    if (ytDlpPath == null) return 0;

    try {
      final result = await _processRunner.run(ytDlpPath, [
        '--flat-playlist',
        '--dump-single-json',
        '--playlist-items',
        '0',
        url,
      ]);

      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout.toString());
        return (data['playlist_count'] as int?) ??
            (data['entries'] as List?)?.length ??
            0;
      }
    } catch (_) {}
    return 0;
  }

  Future<GrabbedVideo?> resolveMetadata(String url) async {
    final ytDlpPath = await _binaryLocator.findYtDlp();
    if (ytDlpPath == null) return null;

    try {
      final result = await _processRunner.run(ytDlpPath, [
        '--dump-json',
        '--skip-download',
        '--no-warnings',
        '--no-playlist',
        '--no-check-certificates',
        url,
      ]);

      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout.toString());
        if (data is Map<String, dynamic>) {
          return GrabbedVideo.fromJson(data);
        }
      }
    } catch (e) {
      LoggerService.e('Failed to resolve metadata for $url', e);
    }
    return null;
  }
}
