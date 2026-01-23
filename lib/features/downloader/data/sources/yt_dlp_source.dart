import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/download_request.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../services/binary_locator.dart';
import '../../../../../services/process_runner.dart';

class YtDlpSource {
  final BinaryLocator _binaryLocator;
  final ProcessRunner _processRunner;

  YtDlpSource(this._binaryLocator, this._processRunner);

  final _downloadProcesses = <String, Process>{};

  /// Fetch video title quickly
  Future<String?> fetchTitle(String url) async {
    try {
      final ytDlp = await _binaryLocator.findYtDlp();
      if (ytDlp == null) return null;

      final result = await _processRunner.run(ytDlp, [
        '--get-title',
        '--no-warnings',
        url,
      ]);

      if (result.exitCode == 0) {
        final title = result.stdout.toString().trim().split('\n').first;
        LoggerService.debug('Fetched title: $title');
        return title;
      }
    } catch (e) {
      LoggerService.w('Failed to fetch title: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchMetadata(String url) async {
    final ytDlp = await _binaryLocator.findYtDlp();
    if (ytDlp == null) throw Exception('yt-dlp binary not found');

    final result = await _processRunner.run(ytDlp, ['-j', url]);
    if (result.exitCode != 0) {
      throw Exception('Failed to fetch metadata: ${result.stderr}');
    }

    return jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
  }

  Stream<DownloadProgressEvent> download(
    String id,
    DownloadRequest request,
  ) async* {
    LoggerService.i('YtDlpSource: Looking for yt-dlp binary...');
    final ytDlp = await _binaryLocator.findYtDlp();
    if (ytDlp == null) {
      LoggerService.e('yt-dlp binary NOT FOUND!');
      throw Exception('yt-dlp binary not found. Please install yt-dlp.');
    }
    LoggerService.i('YtDlpSource: Found yt-dlp: $ytDlp');

    // Build args
    final args = <String>[];

    // Output template - Use proper Windows path separators
    String outputPath;
    if (request.outputFolder != null && request.outputFolder!.isNotEmpty) {
      final folder = request.outputFolder!.replaceAll('/', '\\');
      final filename = request.customFilename ?? '%(title)s.%(ext)s';
      outputPath = '$folder\\$filename';
    } else {
      final downloadsDir = Directory('Downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync();
      }
      outputPath = 'Downloads\\%(title)s.%(ext)s';
    }
    args.add('-o');
    args.add(outputPath);
    LoggerService.debug('Output path: $outputPath');

    // === AUDIO ONLY MODE ===
    if (request.audioOnly) {
      args.add('-x'); // Extract audio
      args.add('--audio-format');
      args.add(request.audioFormat); // mp3, aac, opus
      args.add('--audio-quality');
      args.add('0'); // Best quality
      LoggerService.debug('Mode: Audio only (${request.audioFormat})');
    }
    // === VIDEO MODE ===
    else {
      // Quality selection
      if (request.preferredQuality == 'best') {
        args.add('-f');
        args.add('bestvideo+bestaudio/best');
      } else if (request.preferredQuality == 'worst') {
        args.add('-f');
        args.add('worst');
      } else {
        final height = request.preferredQuality.replaceAll('p', '');
        args.add('-f');
        args.add('bestvideo[height<=$height]+bestaudio/best[height<=$height]');
      }

      // === OUTPUT FORMAT (FFmpeg merge) ===
      // This tells yt-dlp to use FFmpeg to merge/remux to the specified format
      args.add('--merge-output-format');
      args.add(request.outputFormat); // mp4, mkv, webm

      // For MP4: Re-encode audio to AAC for compatibility
      // (Opus/WebM audio codecs don't work in MP4 container)
      if (request.outputFormat == 'mp4') {
        args.add('--postprocessor-args');
        args.add('ffmpeg:-c:a aac -b:a 320k'); // Highest quality AAC
      }

      LoggerService.debug(
        'Quality: ${request.preferredQuality}, Format: ${request.outputFormat}',
      );
    }

    // Embed options (uses FFmpeg internally)
    if (request.embedThumbnail) {
      args.add('--embed-thumbnail');
    }
    if (request.embedSubtitles) {
      args.add('--embed-subs');
      args.add('--sub-langs');
      args.add('all');
    }

    // === COOKIES & HEADERS FOR PROTECTED SITES ===
    if (_requiresCookies(request.url)) {
      // Add browser-like User-Agent (required by many sites)
      args.add('--user-agent');
      args.add(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );

      // Some sites require referer
      args.add('--referer');
      args.add(request.url);

      // Skip certificate verification for problematic sites
      args.add('--no-check-certificates');

      // Use cookies.txt file if provided
      if (request.cookiesFilePath != null &&
          request.cookiesFilePath!.isNotEmpty) {
        final cookieFile = File(request.cookiesFilePath!);
        if (cookieFile.existsSync()) {
          args.add('--cookies');
          args.add(request.cookiesFilePath!);
          LoggerService.debug('Using cookies file: ${request.cookiesFilePath}');
        } else {
          LoggerService.w('Cookies file not found: ${request.cookiesFilePath}');
        }
      }
    }

    // === TOR PROXY ===
    if (request.useTorProxy) {
      const torProxy = 'socks5://127.0.0.1:9050';
      args.add('--proxy');
      args.add(torProxy);
      LoggerService.i('Using Tor Proxy: $torProxy');
    }

    // URL
    args.add(request.url);

    LoggerService.i('YtDlpSource: Running: $ytDlp ${args.join(' ')}');

    // Start process
    final process = await Process.start(ytDlp, args, runInShell: true);
    _downloadProcesses[id] = process;

    // Listen to stderr
    process.stderr.transform(latin1.decoder).listen((data) {
      LoggerService.w('yt-dlp stderr: $data');
    });

    // Regex for progress parsing
    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+([~\d\.]+\w+)\s+at\s+([~\d\.]+\w+/s)\s+ETA\s+(\d+:\d+)',
    );

    // Regex for title extraction
    final destinationRegex = RegExp(
      r'\[download\] Destination: .*[/\\](.+)\.\w+$',
    );

    String? extractedTitle;

    yield* process.stdout
        .transform(latin1.decoder)
        .transform(const LineSplitter())
        .map((line) {
          // Try to extract title from destination line
          if (extractedTitle == null) {
            final destMatch = destinationRegex.firstMatch(line);
            if (destMatch != null) {
              extractedTitle = destMatch.group(1);
              LoggerService.debug('Extracted title: $extractedTitle');
            }
          }

          // Parse progress
          final match = progressRegex.firstMatch(line);
          if (match != null) {
            return DownloadProgressEvent(
              progress: double.parse(match.group(1)!) / 100,
              totalSize: match.group(2) ?? '',
              speed: match.group(3) ?? '',
              eta: match.group(4) ?? '',
              title: extractedTitle,
            );
          }
          return null;
        })
        .where((event) => event != null)
        .cast<DownloadProgressEvent>();

    final exitCode = await process.exitCode;
    _downloadProcesses.remove(id);

    LoggerService.i('yt-dlp process exited with code: $exitCode');
    if (exitCode != 0) {
      throw Exception('yt-dlp exited with code $exitCode. Check logs above.');
    }
  }

  Future<void> cancel(String id) async {
    final process = _downloadProcesses[id];
    if (process != null) {
      LoggerService.i('Killing process for download $id');
      process.kill();
      _downloadProcesses.remove(id);
    }
  }

  /// Check if a site requires browser cookies to bypass protection
  bool _requiresCookies(String url) {
    final protectedDomains = [
      'spankbang.com',
      'pornhub.com',
      'xvideos.com',
      'xnxx.com',
      'xhamster.com',
      'redtube.com',
      'youporn.com',
      'tube8.com',
    ];

    return protectedDomains.any((domain) => url.contains(domain));
  }
}

class DownloadProgressEvent {
  final double progress;
  final String totalSize;
  final String speed;
  final String eta;
  final String? title;

  DownloadProgressEvent({
    required this.progress,
    required this.totalSize,
    required this.speed,
    required this.eta,
    this.title,
  });
}
