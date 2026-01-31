import 'package:flutter/material.dart';
import '../foundation/colors.dart';
import '../foundation/spacing.dart';
import '../foundation/typography.dart';
import '../../../../features/downloader/domain/enums/download_status.dart';

class StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  final String? error;

  const StatusBadge({super.key, required this.status, this.error});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = _getStatusStyle(status);

    return Tooltip(
      message: error ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.smallBorder,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  (Color, String) _getStatusStyle(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return (AppColors.info, 'QUEUED');
      case DownloadStatus.downloading:
        return (AppColors.primary, 'DOWNLOADING');
      case DownloadStatus.processing:
        return (AppColors.warning, 'PROCESSING');
      case DownloadStatus.completed:
        return (AppColors.success, 'COMPLETED');
      case DownloadStatus.failed:
        return (AppColors.error, 'FAILED');
      case DownloadStatus.canceled:
        return (AppColors.textSecondary, 'CANCELED');
      case DownloadStatus.extracting:
        return (AppColors.warning, 'EXTRACTING');
      case DownloadStatus.paused:
        return (AppColors.textSecondary, 'PAUSED');
      case DownloadStatus.duplicate:
        return (AppColors.textSecondary, 'DOUBLON');
    }
  }
}
