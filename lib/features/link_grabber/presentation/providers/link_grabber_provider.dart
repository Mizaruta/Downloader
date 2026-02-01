import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../services/service_providers.dart';
import '../../../../features/downloader/presentation/providers/downloader_provider.dart';
import '../../domain/entities/grabbed_video.dart';

class LinkGrabberState {
  final bool isScanning;
  final List<GrabbedVideo> grabbedVideos;
  final String? error;
  final int totalItems;
  final int processedItems;
  final double estimatedTimeSeconds;

  LinkGrabberState({
    this.isScanning = false,
    this.grabbedVideos = const [],
    this.error,
    this.totalItems = 0,
    this.processedItems = 0,
    this.estimatedTimeSeconds = 0.0,
  });

  LinkGrabberState copyWith({
    bool? isScanning,
    List<GrabbedVideo>? grabbedVideos,
    String? error,
    int? totalItems,
    int? processedItems,
    double? estimatedTimeSeconds,
  }) {
    return LinkGrabberState(
      isScanning: isScanning ?? this.isScanning,
      grabbedVideos: grabbedVideos ?? this.grabbedVideos,
      error: error,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
    );
  }
}

class LinkGrabberNotifier extends StateNotifier<LinkGrabberState> {
  final Ref ref;

  LinkGrabberNotifier(this.ref) : super(LinkGrabberState());

  Future<void> scanUrl(String url, {bool deepScan = false}) async {
    if (url.trim().isEmpty) return;

    state = state.copyWith(
      isScanning: true,
      error: null,
      grabbedVideos: [],
      totalItems: 0,
      processedItems: 0,
      estimatedTimeSeconds: 0,
    );

    try {
      final service = ref.read(linkGrabberServiceProvider);

      // Phase 1: Probe total count
      final total = await service.getPlaylistCount(url);
      state = state.copyWith(totalItems: total);

      // Phase 2: Instant Fast Scan (get URLs/IDs)
      final startTime = DateTime.now();
      final fastStream = service.extractPlaylistMetadataStream(
        url,
        deepScan: false,
      );

      List<GrabbedVideo> initialVideos = [];
      await for (final video in fastStream) {
        initialVideos.add(video);
        state = state.copyWith(
          grabbedVideos: initialVideos,
          processedItems: initialVideos.length,
        );
      }

      state = state.copyWith(totalItems: initialVideos.length);

      // Phase 3: Parallel Deep Scan (if requested)
      if (deepScan && initialVideos.isNotEmpty) {
        final List<GrabbedVideo> toProcess = [...initialVideos];
        int resolvedCount = 0;
        const int maxWorkers = 8; // Parallel workers

        // Helper to update a video in the state
        void updateVideo(GrabbedVideo oldVideo, GrabbedVideo newVideo) {
          final list = [...state.grabbedVideos];
          final index = list.indexOf(oldVideo);
          if (index != -1) {
            list[index] = newVideo;
            state = state.copyWith(grabbedVideos: list);
          }
        }

        // Worker logic
        Future<void> worker() async {
          while (true) {
            GrabbedVideo? video;
            // In Dart, synchronous code between awaits is atomic.
            // No explicit lock needed for List.removeAt(0) in a single-threaded event loop.
            if (toProcess.isNotEmpty) {
              video = toProcess.removeAt(0);
            }
            if (video == null) break;

            final resolvedVideo = await service.resolveMetadata(video.url);
            if (resolvedVideo != null) {
              resolvedVideo.isSelected = video.isSelected;
              updateVideo(video, resolvedVideo);
            }

            resolvedCount++;

            // Update ETA
            final elapsed = DateTime.now().difference(startTime).inMilliseconds;
            final msPerItem = elapsed / (resolvedCount + 1);
            final remainingItems = initialVideos.length - resolvedCount;
            state = state.copyWith(
              processedItems: resolvedCount,
              estimatedTimeSeconds: (remainingItems * msPerItem) / 1000,
            );
          }
        }

        // Spawn workers
        await Future.wait(List.generate(maxWorkers, (_) => worker()));
      }

      state = state.copyWith(
        isScanning: false,
        processedItems: initialVideos.length,
        estimatedTimeSeconds: 0,
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
      LoggerService.e('Scan failed', e);
    }
  }

  void toggleSelection(GrabbedVideo video) {
    final updatedList = state.grabbedVideos.map((v) {
      if (v == video) {
        v.isSelected = !v.isSelected;
      }
      return v;
    }).toList();
    state = state.copyWith(grabbedVideos: updatedList);
  }

  void toggleAll(bool select) {
    final updatedList = state.grabbedVideos.map((v) {
      v.isSelected = select;
      return v;
    }).toList();
    state = state.copyWith(grabbedVideos: updatedList);
  }

  void addSelectedToQueue() {
    final selected = state.grabbedVideos.where((v) => v.isSelected).toList();
    final urls = selected.map((v) => v.url).toList();
    final downloader = ref.read(downloadListProvider.notifier);

    downloader.startDownloadsBatch(urls);

    LoggerService.i('Added ${selected.length} videos to queue');
  }
}

final linkGrabberProvider =
    StateNotifierProvider<LinkGrabberNotifier, LinkGrabberState>((ref) {
      return LinkGrabberNotifier(ref);
    });
