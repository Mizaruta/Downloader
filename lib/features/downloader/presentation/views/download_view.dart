import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modern_downloader/theme/ios_theme.dart';
import 'package:modern_downloader/theme/palette.dart';
import 'package:modern_downloader/core/ui/widgets/animated_input_field.dart';
import 'package:modern_downloader/core/ui/glass_card.dart';
import '../providers/downloader_provider.dart';
import '../widgets/download_card.dart';

class DownloadView extends ConsumerStatefulWidget {
  const DownloadView({super.key});

  @override
  ConsumerState<DownloadView> createState() => _DownloadViewState();
}

class _DownloadViewState extends ConsumerState<DownloadView> {
  final TextEditingController _urlController = TextEditingController();
  String _selectedCategory = 'all'; // 'all', 'streaming', 'social', 'adult'
  final ScrollController _scrollController = ScrollController();

  // Data
  final List<SiteCategory> _categories = [
    SiteCategory(
      id: 'streaming',
      name: 'Streaming',
      icon: Icons.live_tv_rounded,
      color: Palette.neonPurple,
      sites: [
        Site(
          name: 'YouTube',
          icon: Icons.play_arrow_rounded,
          color: Color(0xFFFF0000),
        ),
        Site(
          name: 'Twitch',
          icon: Icons.videocam_rounded,
          color: Color(0xFF9146FF),
        ),
        Site(name: 'Kick', icon: Icons.circle, color: Color(0xFF53FC18)),
        Site(
          name: 'Dailymotion',
          icon: Icons.movie_creation_rounded,
          color: Color(0xFF0066DC),
        ),
      ],
    ),
    SiteCategory(
      id: 'social',
      name: 'Social',
      icon: Icons.share_rounded,
      color: Palette.neonBlue,
      sites: [
        Site(
          name: 'Twitter/X',
          icon: Icons.alternate_email_rounded,
          color: Colors.white,
        ),
        Site(
          name: 'TikTok',
          icon: Icons.music_note_rounded,
          color: Color(0xFFFF0050),
        ),
        Site(
          name: 'Instagram',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE4405F),
        ),
        Site(
          name: 'Reddit',
          icon: Icons.forum_rounded,
          color: Color(0xFFFF4500),
        ),
      ],
    ),
    SiteCategory(
      id: 'adult',
      name: '18+',
      icon: Icons.eighteen_up_rating_rounded,
      color: Palette.error,
      sites: [
        Site(
          name: 'Pornhub',
          icon: Icons.public_rounded,
          color: Color(0xFFF7971E),
        ),
        Site(
          name: 'SpankBang',
          icon: Icons.speed_rounded,
          color: Color(0xFFFF1744),
        ),
        Site(
          name: 'XVideos',
          icon: Icons.video_library_rounded,
          color: Color(0xFFE91E63),
        ),
      ],
    ),
  ];

  void _startDownload(String url) {
    if (url.isNotEmpty) {
      ref.read(downloadListProvider.notifier).startDownload(url);
      _urlController.clear();
      // Scroll to bottom to see download
      Future.delayed(300.ms, () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: 500.ms,
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                              'Downloader',
                              style: IOSTheme.textTheme.displayLarge,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.1),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.neonBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Palette.neonBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'PRO',
                            style: IOSTheme.textTheme.labelSmall?.copyWith(
                              color: Palette.neonBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).scale(),
                      ],
                    ),
                    const Gap(32),

                    // Search Bar
                    AnimatedInputField(
                      controller: _urlController,
                      hintText: _getSearchPlaceholder(),
                      onSubmitted: _startDownload,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // Categories Selector
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140, // Taller for cards
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildCategoryCard(
                      'all',
                      'All Sites',
                      Icons.apps_rounded,
                      Palette.neonCyan,
                    ),
                    const Gap(16),
                    ..._categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildCategoryCard(
                          c.id,
                          c.name,
                          c.icon,
                          c.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),

            const SliverToBoxAdapter(child: Gap(32)),

            // Quick Links (Dynamic Grid)
            if (_selectedCategory != 'all')
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cat = _categories.firstWhere(
                        (c) => c.id == _selectedCategory,
                      );
                      final site = cat.sites[index];
                      return _buildSiteButton(site);
                    },
                    childCount: _categories
                        .firstWhere((c) => c.id == _selectedCategory)
                        .sites
                        .length,
                  ),
                ),
              ),

            if (_selectedCategory != 'all')
              const SliverToBoxAdapter(child: Gap(40)),

            // Downloads Sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('History', style: IOSTheme.textTheme.titleLarge),
                    const Spacer(),
                    if (downloads.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.glassWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${downloads.length}',
                          style: IOSTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(16)),

            // List
            if (downloads.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = downloads[index];
                  // Use Padding for separation
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: DownloadCard(
                      item: item,
                      onCancel: () {
                        // Logic handled in provider/card usually or add callback
                      },
                    ).animate().fadeIn().slideX(begin: 0.1, delay: (index * 50).ms),
                  );
                }, childCount: downloads.length),
              ),

            const SliverToBoxAdapter(child: Gap(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String id,
    String name,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCategory == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutBack,
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Palette.glassWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Palette.borderWhite,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : Colors.transparent,
              blurRadius: isSelected ? 16 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : Palette.glassWhiteHover,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Palette.textSecondary,
                size: 24,
              ),
            ),
            const Gap(12),
            Text(
              name,
              style: IOSTheme.textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white : Palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteButton(Site site) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        // Feature: Fill search bar with site domain or open browser?
        // For now just fill controller hint maybe?
      },
      child: Row(
        children: [
          Icon(site.icon, color: site.color, size: 24),
          const Gap(12),
          Expanded(
            child: Text(
              site.name,
              style: IOSTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Palette.textQuaternary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Gap(60),
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.glassWhite,
              ),
              child: Icon(
                Icons.download_done_rounded,
                size: 40,
                color: Palette.textTertiary,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
              duration: 2.seconds,
            ),
        const Gap(24),
        Text(
          'Ready to Download',
          style: IOSTheme.textTheme.titleLarge?.copyWith(
            color: Palette.textSecondary,
          ),
        ),
        const Gap(8),
        Text(
          'Paste a link above to start',
          style: IOSTheme.textTheme.bodyMedium?.copyWith(
            color: Palette.textQuaternary,
          ),
        ),
      ],
    );
  }

  String _getSearchPlaceholder() {
    switch (_selectedCategory) {
      case 'streaming':
        return 'Paste YouTube, Twitch link...';
      case 'social':
        return 'Paste Twitter, TikTok link...';
      case 'adult':
        return 'Paste 18+ link...';
      default:
        return 'Paste any video link...';
    }
  }
}

class SiteCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<Site> sites;
  const SiteCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sites,
  });
}

class Site {
  final String name;
  final IconData icon;
  final Color color;
  const Site({required this.name, required this.icon, required this.color});
}
