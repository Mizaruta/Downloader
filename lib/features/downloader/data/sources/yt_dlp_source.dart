import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/download_request.dart';
import '../../domain/exceptions/yt_dlp_exception.dart';
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

    // === SPEED OPTIMIZATION FLAGS ===
    // Check for aria2c (The nuclear option for speed)
    final aria2cPath = await _binaryLocator.findAria2c();
    if (aria2cPath != null) {
      LoggerService.i('Activating Aria2c engine: $aria2cPath');
      args.addAll([
        '--downloader',
        'aria2c',
        '--downloader-args',
        'aria2c:-x 16 -s 16 -k 1M',
      ]);
    } else {
      LoggerService.i('Aria2c not found, using native optimized downloader.');
      // Native HTTP Downloader optimizations (Only if aria2c is missing)
      args.addAll([
        '--concurrent-fragments',
        '8',
      ]); // Reduced from 16 to be safe if native
      args.addAll(['--buffer-size', '16M']);
      args.addAll(['--http-chunk-size', '10M']);
    }

    // Skip playlist checks
    args.add('--no-playlist');

    // Retry on errors (keep .part files for resume capability)
    args.addAll(['--retries', '10']);
    args.addAll(['--fragment-retries', '10']);

    // Force IPv4 if IPv6 is slow/unstable (common issue)
    // args.add('--force-ipv4');

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

    // === BROWSER COOKIES FOR ALL SITES ===
    // Always extract cookies from Firefox first (handles most auth cases)
    // Firefox is preferred because it doesn't have Chrome's lockfile issue
    args.addAll(['--cookies-from-browser', 'firefox']);
    LoggerService.i('Using Firefox cookies for authentication');

    // === HEADERS FOR PROTECTED SITES ===
    if (_requiresCookies(request.url)) {
      // Add browser-like User-Agent (required by many sites)
      args.addAll([
        '--user-agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ]);

      // Some sites require referer
      args.addAll(['--referer', request.url]);

      // Skip certificate verification for problematic sites
      args.add('--no-check-certificates');
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

    // Capture specific errors from stderr
    // We store the first "critical" error we find to throw it later if the process fails.
    YtDlpException? detectedException;

    process.stderr.transform(latin1.decoder).listen((data) {
      LoggerService.w('yt-dlp stderr: $data');

      if (detectedException != null) return; // Already found a specific error

      final check = data.toLowerCase();
      if (check.contains('video unavailable')) {
        detectedException = VideoUnavailableException(log: data);
      } else if (check.contains('private video') ||
          check.contains('this video is private')) {
        detectedException = PrivateVideoException(log: data);
      } else if (check.contains(
            'uploader has not made this video available in your country',
          ) ||
          check.contains('geo-restricted')) {
        detectedException = GeoBlockedException(log: data);
      } else if (check.contains('copyright claim') ||
          check.contains('removed by the user')) {
        detectedException = CopyrightException(log: data);
      } else if (check.contains('network is unreachable') ||
          check.contains('connection refused') ||
          check.contains('timed out')) {
        detectedException = NetworkException(log: data);
      } else if (check.contains('sign in to confirm your age')) {
        detectedException = AgeRestrictedException(log: data);
      } else if (check.contains('this live event will begin in') ||
          check.contains('is offline')) {
        detectedException = LiveStreamOfflineException(log: data);
      }
    });

    // Regex for progress parsing (standard format)
    // Format: [download] 24.6% of ~ 140.29MiB at 2.70MiB/s ETA 00:39 (frag 32/132)
    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+~?\s*([~\d\.]+\w+)\s+at\s+([~\d\.]+\w+/s)\s+ETA\s+([\d:]+)',
    );

    // Regex for HLS/fragment progress (used by XVideos, Twitter, etc.)
    // Format: [download] 100% of 1.27MiB in 00:00:00 at 4.94MiB/s
    final hlsProgressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+~?\s*([~\d\.]+\w+)\s+in\s+[\d:]+\s+at\s+([~\d\.]+\w+/s)',
    );

    // Regex for "already downloaded"
    // Format: [download] C:\Path\To\File.mp4 has already been downloaded
    final alreadyDownloadedRegex = RegExp(
      r'\[download\]\s+(.*)\s+has already been downloaded',
    );

    // Regex for title extraction from destination line
    final destinationRegex = RegExp(
      r'\[download\] Destination: .*[/\\](.+)\.\w+$',
    );

    // Additional regex for extracting title from Merger output
    final mergerRegex = RegExp(r'\[Merger\] Merging formats into "(.+)\.\w+"');

    String? extractedTitle;
    String currentStep = 'Initializing...';
    String? currentFilePath;

    yield* process.stdout
        .transform(latin1.decoder)
        .transform(const LineSplitter())
        .asyncExpand((line) async* {
          // Log every line for debugging
          LoggerService.debug('yt-dlp: $line');

          // Detect current step from yt-dlp output
          if (line.contains('[download]')) {
            if (line.contains('Downloading') && line.contains('format')) {
              currentStep = 'Downloading video...';
            } else if (line.contains('Destination')) {
              currentStep = 'Saving file...';
            }
          } else if (line.contains('[Merger]')) {
            currentStep = 'Merging audio/video...';
          } else if (line.contains('[EmbedThumbnail]')) {
            currentStep = 'Embedding thumbnail...';
          } else if (line.contains('[ExtractAudio]')) {
            currentStep = 'Extracting audio...';
          } else if (line.contains('[ffmpeg]')) {
            currentStep = 'Processing with FFmpeg...';
          } else if (line.contains('[PornHub]') ||
              line.contains('[YouTube]') ||
              line.contains('[twitter]')) {
            currentStep = 'Extracting metadata...';
          }

          // Try to extract title from destination line
          if (extractedTitle == null) {
            var titleMatch = destinationRegex.firstMatch(line);
            titleMatch ??= mergerRegex.firstMatch(line);

            if (titleMatch != null) {
              extractedTitle = titleMatch.group(1);
              LoggerService.debug('Extracted title: $extractedTitle');
              // Emit an event with the title only (progress -1 = don't update progress)
              yield DownloadProgressEvent(
                progress: -1, // Sentinel: don't update progress, only title
                totalSize: '',
                speed: '',
                eta: '',
                title: extractedTitle,
                step: currentStep,
              );
            }
          }

          // Check for "Destination" to get file path
          final destinationMatch = destinationRegex.firstMatch(line);
          if (destinationMatch != null) {
            // Need a regex that captures the FULL path, standard destinationRegex above captures filename
            // reuse destinationRegex or make a new one?
            // Existing regex: r'\[download\] Destination: .*[/\\](.+)\.\w+$' captures filename.
            // Let's capture the full path from the line.
            final fullPathRegex = RegExp(r'\[download\] Destination: (.*)$');
            final fullMatch = fullPathRegex.firstMatch(line);
            if (fullMatch != null) {
              currentFilePath = fullMatch.group(1);
            }
          }

          // Check for Merger output for file path (merged file)
          final mergerMatch = mergerRegex.firstMatch(
            line,
          ); // "Merging formats into "(.+)\.\w+""
          if (mergerMatch != null) {
            // The group 1 is filename? Let's assume relative path or full path.
            // Usually yt-dlp outputs relative to CWD or absolute.
            // We'll rely on what we have.
            // Actually, simplest is to grab what's in quotes.
            final fullMergeRegex = RegExp(
              r'\[Merger\] Merging formats into "(.*)"',
            );
            final fm = fullMergeRegex.firstMatch(line);
            if (fm != null) {
              currentFilePath = fm.group(1);
            }
          }

          // Check for "already downloaded"
          final alreadyMatch = alreadyDownloadedRegex.firstMatch(line);
          if (alreadyMatch != null) {
            currentFilePath = alreadyMatch.group(1);
            LoggerService.i('File already exists: $currentFilePath');
            yield DownloadProgressEvent(
              progress: 1.0,
              totalSize: '',
              speed: '',
              eta: '',
              title: extractedTitle,
              step: 'Completed (Already exists)',
              filePath: currentFilePath,
            );
            return;
          }

          // Parse progress (try standard format first, then HLS format)
          var match = progressRegex.firstMatch(line);
          if (match != null) {
            final progressPercent = double.parse(match.group(1)!) / 100;
            final totalSize = match.group(2) ?? '';
            yield DownloadProgressEvent(
              progress: progressPercent,
              totalSize: totalSize,
              downloadedSize: _calculateDownloadedSize(
                progressPercent,
                totalSize,
              ),
              speed: match.group(3) ?? '',
              eta: match.group(4) ?? '',
              title: extractedTitle,
              step: currentStep,
              filePath: currentFilePath,
            );
          } else {
            // Try HLS format (no ETA, uses "in" instead of "at")
            match = hlsProgressRegex.firstMatch(line);
            if (match != null) {
              final progressPercent = double.parse(match.group(1)!) / 100;
              final totalSize = match.group(2) ?? '';
              yield DownloadProgressEvent(
                progress: progressPercent,
                totalSize: totalSize,
                downloadedSize: _calculateDownloadedSize(
                  progressPercent,
                  totalSize,
                ),
                speed: match.group(3) ?? '',
                eta: '', // HLS format doesn't have ETA
                title: extractedTitle,
                step: currentStep,
                filePath: currentFilePath,
              );
            }
          }
        });

    final exitCode = await process.exitCode;
    _downloadProcesses.remove(id);

    LoggerService.i('yt-dlp process exited with code: $exitCode');

    if (exitCode != 0) {
      // If we detected a specific exception during stderr parsing, throw it now.
      if (detectedException != null) {
        throw detectedException!;
      }

      // Otherwise fallback to generic exception
      throw YtDlpException('yt-dlp exited with code $exitCode. See logs.');
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

  /// Calculate downloaded size from progress and total size
  /// e.g., 50% of "300MiB" = "150.0MiB"
  String _calculateDownloadedSize(double progress, String totalSize) {
    if (totalSize.isEmpty || progress <= 0) return '';

    // Parse the size value and unit from strings like "300MiB", "1.5GiB", "~500KiB"
    final sizeRegex = RegExp(r'~?(\d+\.?\d*)\s*(\w+)');
    final match = sizeRegex.firstMatch(totalSize);
    if (match == null) return '';

    final totalValue = double.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2) ?? '';

    final downloadedValue = totalValue * progress;
    return '${downloadedValue.toStringAsFixed(1)}$unit';
  }

  /// Check if a site requires browser cookies to bypass protection
  bool _requiresCookies(String url) {
    final protectedDomains = [
      // Social media
      'twitter.com',
      'x.com',
      // Adult sites
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
  final String downloadedSize; // Calculated from progress * totalSize
  final String speed;
  final String eta;
  final String? title;
  final String step; // Current step (e.g., "Downloading...", "Merging...")
  final String? filePath;

  DownloadProgressEvent({
    required this.progress,
    required this.totalSize,
    this.downloadedSize = '',
    required this.speed,
    required this.eta,
    this.title,
    this.step = '',
    this.filePath,
  });
}
