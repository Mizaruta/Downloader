import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/link_grabber_provider.dart';

class LinkGrabberScreen extends ConsumerStatefulWidget {
  const LinkGrabberScreen({super.key});

  @override
  ConsumerState<LinkGrabberScreen> createState() => _LinkGrabberScreenState();
}

class _LinkGrabberScreenState extends ConsumerState<LinkGrabberScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(linkGrabberProvider);
    final notifier = ref.read(linkGrabberProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Grabber'),
        actions: [
          if (state.grabbedVideos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.playlist_add_check),
              tooltip: 'Add Selected to Download Queue',
              onPressed: () {
                final count = state.grabbedVideos
                    .where((v) => v.isSelected)
                    .length;
                if (count == 0) return;

                notifier.addSelectedToQueue();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $count videos to download queue'),
                  ),
                );
                Navigator.pop(
                  context,
                ); // Go back to main screen to see downloads
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Channel or Playlist URL',
                      hintText: 'https://rumble.com/c/SomeChannel',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (val) => notifier.scanUrl(val),
                  ),
                ),
                const Gap(10),
                FilledButton.icon(
                  onPressed: state.isScanning
                      ? null
                      : () => notifier.scanUrl(
                          _urlController.text,
                          deepScan: true,
                        ),
                  icon: state.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rocket_launch),
                  label: const Text('Deep Scan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const Gap(10),
                OutlinedButton.icon(
                  onPressed: state.isScanning
                      ? null
                      : () => notifier.scanUrl(
                          _urlController.text,
                          deepScan: false,
                        ),
                  icon: const Icon(Icons.search),
                  label: const Text('Fast Scan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (state.isScanning) ...[
              const Gap(10),
              LinearProgressIndicator(
                value: (state.totalItems > 0)
                    ? (state.processedItems / state.totalItems)
                    : null,
              ),
              const Gap(5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanned: ${state.processedItems}${state.totalItems > 0 ? ' / ${state.totalItems}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (state.estimatedTimeSeconds > 0)
                    Text(
                      '~${_formatDuration(state.estimatedTimeSeconds.toInt())} remaining',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ],
            const Gap(10),
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.1),
                child: Text(
                  'Error: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const Gap(10),
            if (state.grabbedVideos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${state.grabbedVideos.length} items found'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => notifier.toggleAll(true),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => notifier.toggleAll(false),
                        child: const Text('Deselect All'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
            ],
            Expanded(
              child: state.grabbedVideos.isEmpty && !state.isScanning
                  ? const Center(child: Text('Enter a URL to scan for videos.'))
                  : ListView.builder(
                      itemCount: state.grabbedVideos.length,
                      itemBuilder: (context, index) {
                        final video = state.grabbedVideos[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: video.isSelected,
                              onChanged: (val) =>
                                  notifier.toggleSelection(video),
                            ),
                            title: Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${video.duration > 0 ? 'Duration: ${_formatDuration(video.duration.toInt())} • ' : ''}'
                              '${video.fileSize != null ? 'Size: ${_formatFileSize(video.fileSize!)} • ' : ''}'
                              'ID: ${video.id}',
                            ),
                            trailing: video.thumbnail.isNotEmpty
                                ? Image.network(
                                    video.thumbnail,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.movie),
                            onTap: () => notifier.toggleSelection(video),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
