import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/daily_mix.dart';
import '../providers/home_provider.dart';
import '../providers/mood_mix_provider.dart';
import '../widgets/mix_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _playTrack(Track track, List<Track> queue) {
    ref.read(playerControllerProvider.notifier).playTrack(track, queue: queue);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final theme = Theme.of(context);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final playerState = ref.watch(playerControllerProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    Future<void> onRefresh() async {
      ref.invalidate(recentlyPlayedProvider);
      ref.invalidate(moodMixProvider);
      try {
        await ref.read(recentlyPlayedProvider.future);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: t.accent,
          backgroundColor: t.field,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(bottom: AppSpacing.bottomPlayerPadding),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenInset,
                          AppSpacing.space4,
                          AppSpacing.screenInset,
                          AppSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 48),
                            Expanded(
                              child: Text(
                                _greeting(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: t.textPrimary,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                            AppIconButton(
                              icon: Icons.settings_outlined,
                              semanticLabel: 'Settings',
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ),

                      // Offline banner
                      if (!isOnline)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenInset,
                            AppSpacing.space2,
                            AppSpacing.screenInset,
                            AppSpacing.space2,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 72),
                            decoration: BoxDecoration(
                              color: t.raised,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xxl),
                              border: Border.all(color: t.border),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space4,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_off,
                                    color: t.textPrimary, size: 20),
                                const SizedBox(width: AppSpacing.space3),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Offline mode',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: t.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Showing cached content',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: t.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Continue listening section
                      const AppSectionHeader(title: 'Continue Listening'),
                      recentlyPlayedAsync.when(
                        data: (tracks) {
                          if (tracks.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenInset,
                              ),
                              child: AppEmptyState(
                                icon: Icons.history_rounded,
                                title: 'No recently played tracks',
                                actionLabel: 'Search music',
                                onAction: () => context.go('/search'),
                              ),
                            );
                          }
                          final first = tracks.first;
                          final isCurrent =
                              playerState.currentTrack?.sourceId ==
                                  first.sourceId;
                          final progress =
                              playerState.duration.inMilliseconds > 0
                                  ? (playerState.position.inMilliseconds /
                                          playerState.duration.inMilliseconds)
                                      .clamp(0.0, 1.0)
                                  : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenInset,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 98),
                              decoration: BoxDecoration(
                                color: t.field,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xxl),
                                border: Border.all(color: t.border),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.xxl,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xxl,
                                        ),
                                        onTap: () => _playTrack(first, tracks),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.space3,
                                    ),
                                    child: Row(
                                      children: [
                                        AppArtwork(
                                          localPath: first.localThumbnailPath,
                                          imageUrl: first.thumbnailUrl,
                                          size: 68,
                                          radius: AppRadius.artworkSmall,
                                        ),
                                        const SizedBox(
                                            width: AppSpacing.space3),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                first.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: t.textPrimary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: AppSpacing.xs),
                                              Text(
                                                '${first.artist} · '
                                                '${first.source.name}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: t.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: AppSpacing.space2),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: 198,
                                                ),
                                                child: Container(
                                                  height: 3,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: t.track,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppRadius.sm),
                                                  ),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: isCurrent
                                                      ? FractionallySizedBox(
                                                          widthFactor: progress,
                                                          child: Container(
                                                            color: t.accent,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                            width: AppSpacing.space2),
                                        Semantics(
                                          button: true,
                                          label: 'Play ${first.title}',
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () =>
                                                _playTrack(first, tracks),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: t.accent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.play_arrow_rounded,
                                                color: t.onAccent,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Container(
                            height: 98,
                            decoration: BoxDecoration(
                              color: t.raised,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xxl),
                            ),
                          ),
                        ),
                        error: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Text(
                            'Unable to load',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Quick cards
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenInset,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.download_rounded,
                                title: 'Downloaded',
                                meta: 'Offline cache',
                                onTap: () =>
                                    context.push('/library/downloaded'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.folder_outlined,
                                title: 'Device songs',
                                meta: 'On this device',
                                onTap: () =>
                                    context.push('/library/device-songs'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Daily mix section: five fixed mood cards.
                      const AppSectionHeader(title: 'Daily Mix'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenInset,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final mood in DailyMixMood.values)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.space3,
                                ),
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final artworkUrls = ref
                                            .watch(moodMixProvider(mood))
                                            .valueOrNull
                                            ?.artworkUrls ??
                                        const <String>[];
                                    return MixCard(
                                      mood: mood,
                                      artworkUrls: artworkUrls,
                                      onTap: () => context.push(
                                        '/daily-mix/${mood.name}',
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Recently played section
                      if (recentlyPlayedAsync.valueOrNull?.isNotEmpty ?? true)
                        const AppSectionHeader(
                          title: 'Recently Played',
                        ),
                      recentlyPlayedAsync.when(
                        data: (tracks) {
                          if (tracks.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final list = tracks.take(4).toList();
                          return Column(
                            children: list.map((track) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screenInset,
                                  0,
                                  AppSpacing.screenInset,
                                  AppSpacing.space2,
                                ),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 54),
                                  decoration: BoxDecoration(
                                    color: t.surface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: t.border),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                      onTap: () => _playTrack(
                                        track,
                                        recentlyPlayedAsync.value ?? list,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.space3,
                                          vertical: AppSpacing.space2,
                                        ),
                                        child: Row(
                                          children: [
                                            AppArtwork(
                                              localPath:
                                                  track.localThumbnailPath,
                                              imageUrl: track.thumbnailUrl,
                                              size: 34,
                                              radius: AppRadius.md,
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.space3),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    track.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: t.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    track.artist,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: t.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(track.durationMs),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: t.textSecondary,
                                                fontSize: 11,
                                                letterSpacing: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: t.raised,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                        error: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Text(
                            'Unable to load',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: t.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.raised,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: t.textPrimary, size: 20),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: t.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: t.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
