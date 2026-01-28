enum DownloadStatus {
  queued,
  extracting, // Getting metadata
  downloading,
  processing, // ffmpeg merge/convert
  completed,
  failed,
  canceled,
  paused,
  duplicate,
}
