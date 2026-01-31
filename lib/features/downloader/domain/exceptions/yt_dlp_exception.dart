class YtDlpException implements Exception {
  final String message;
  final String? originalLog;

  YtDlpException(this.message, {this.originalLog});

  @override
  String toString() => message;
}

class VideoUnavailableException extends YtDlpException {
  VideoUnavailableException({String? log})
    : super("Video is unavailable", originalLog: log);
}

class PrivateVideoException extends YtDlpException {
  PrivateVideoException({String? log})
    : super("Video is private or requires login", originalLog: log);
}

class GeoBlockedException extends YtDlpException {
  GeoBlockedException({String? log})
    : super("Video is not available in your country", originalLog: log);
}

class CopyrightException extends YtDlpException {
  CopyrightException({String? log})
    : super("Video removed due to copyright", originalLog: log);
}

class NetworkException extends YtDlpException {
  NetworkException({String? log})
    : super("Network error during download", originalLog: log);
}

class AgeRestrictedException extends YtDlpException {
  AgeRestrictedException({String? log})
    : super("Video is age restricted", originalLog: log);
}

class LiveStreamOfflineException extends YtDlpException {
  LiveStreamOfflineException({String? log})
    : super("Live stream is currently offline", originalLog: log);
}
