import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

/// State for the integrated media player
class MediaPlayerState {
  final bool isOpen;
  final String? currentFile;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;

  const MediaPlayerState({
    this.isOpen = false,
    this.currentFile,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
  });

  MediaPlayerState copyWith({
    bool? isOpen,
    String? currentFile,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
  }) {
    return MediaPlayerState(
      isOpen: isOpen ?? this.isOpen,
      currentFile: currentFile ?? this.currentFile,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

/// Manages the media player lifecycle using media_kit
class MediaPlayerNotifier extends StateNotifier<MediaPlayerState> {
  late final Player _player;

  /// Kept as a mutable field (not in immutable state) to avoid
  /// copyWith null issues when streams fire rapidly.
  bool _isSeeking = false;
  bool get isSeeking => _isSeeking;

  MediaPlayerNotifier() : super(const MediaPlayerState()) {
    _player = Player();
    _setupListeners();
  }

  Player get player => _player;

  void _setupListeners() {
    _player.stream.playing.listen((playing) {
      if (mounted) state = state.copyWith(isPlaying: playing);
    });
    _player.stream.position.listen((position) {
      // Don't update position from stream while user is dragging the seek bar
      if (mounted && !_isSeeking) {
        state = state.copyWith(position: position);
      }
    });
    _player.stream.duration.listen((duration) {
      if (mounted) state = state.copyWith(duration: duration);
    });
    _player.stream.volume.listen((volume) {
      if (mounted) state = state.copyWith(volume: volume / 100.0);
    });
    _player.stream.rate.listen((rate) {
      if (mounted) state = state.copyWith(playbackSpeed: rate);
    });
    _player.stream.completed.listen((completed) {
      if (mounted && completed) {
        state = state.copyWith(isPlaying: false);
      }
    });
  }

  /// Open a file for playback — enters true Windows fullscreen
  Future<void> openFile(String filePath) async {
    if (!File(filePath).existsSync()) return;

    // 1. Enter fullscreen first
    await windowManager.setFullScreen(true);

    // 2. Small delay to let the window resize/context switch happen
    // Critical for first launch to avoid black screen texture issues
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Keep open=true to show the UI (mounts Video widget) and set file
    state = state.copyWith(isOpen: true, currentFile: filePath);

    // 4. Start playback
    await _player.open(Media(filePath));
  }

  /// Close the player — exits fullscreen
  Future<void> close() async {
    await _player.stop();
    // Restore windowed mode
    await windowManager.setFullScreen(false);
    state = const MediaPlayerState();
  }

  void togglePlayPause() {
    _player.playOrPause();
  }

  /// Called when user starts dragging the seek bar
  void startSeeking() {
    _isSeeking = true;
  }

  /// Called while user drags — just updates the displayed position
  void seekPreview(Duration position) {
    state = state.copyWith(position: position);
  }

  /// Called when user releases the seek bar — actually seeks the player
  void seek(Duration position) {
    _player.seek(position);
    _isSeeking = false;
    state = state.copyWith(position: position);
  }

  void setVolume(double volume) {
    _player.setVolume(volume * 100.0);
  }

  void setPlaybackSpeed(double speed) {
    _player.setRate(speed);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final mediaPlayerProvider =
    StateNotifierProvider<MediaPlayerNotifier, MediaPlayerState>(
      (ref) => MediaPlayerNotifier(),
    );
