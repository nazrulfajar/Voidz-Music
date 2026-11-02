import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<String> _moods = <String>[
    'All',
    'Energize',
    'Workout',
    'Relax',
    'Commute',
    'Focus',
    'Podcasts',
  ];

  static const List<double> _waveHeights = <double>[
    40,
    64,
    32,
    80,
    56,
    48,
    72,
    40,
    88,
    52,
    68,
    36,
    60,
    76,
    44,
    56,
    64,
    48,
  ];

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

  void _openFilterSheet() {
    final t = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.panel,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final selectedMood = ref.watch(homeMoodProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenInset,
                  AppSpacing.space4,
                  AppSpacing.screenInset,
                  AppSpacing.space6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: t.textPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.handle),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: _moods.map((mood) {
                        final selected = selectedMood == mood;
                        return ChoiceChip(
                          label: Text(mood),
                          selected: selected,
                          onSelected: (_) {
                            ref.read(homeMoodProvider.notifier).state = mood;
                          },
                          backgroundColor: t.field,
                          selectedColor: t.raised,
                          labelStyle: TextStyle(
                            color: selected ? t.textPrimary : t.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            side: BorderSide(
                              color: selected ? t.focusedBorder : t.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.push('/settings');
                      },
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space3,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined,
                                color: t.textPrimary, size: 20),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Text(
                                'Settings',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: t.textPrimary),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: t.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final theme = Theme.of(context);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final quickPicksAsync = ref.watch(quickPicksProvider);
    final playerState = ref.watch(playerControllerProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    Future<void> onRefresh() async {
      ref.invalidate(recentlyPlayedProvider);
      ref.invalidate(quickPicksProvider);
      try {
        await ref.read(recentlyPlayedProvider.future);
        await ref.read(quickPicksProvider.future);
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
                        child: SizedBox(
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  _greeting(),
                                  style:
                                      theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Material(
                                    color: t.raised,
                                    shape: CircleBorder(
                                      side: BorderSide(color: t.border),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: _openFilterSheet,
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: t.textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            height: 72,
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
                              child: Text(
                                'No recently played tracks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.textMuted,
                                ),
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
                              height: 98,
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
                                        GestureDetector(
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

                      // Daily mix section
                      AppSectionHeader(
                        title: 'Daily Mix',
                        actionLabel: 'View all',
                        onAction: () => context.push('/daily-mix'),
                      ),
                      quickPicksAsync.when(
                        data: (tracks) {
                          if (tracks.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenInset,
                              ),
                              child: Text(
                                'Nothing to suggest right now',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.textMuted,
                                ),
                              ),
                            );
                          }
                          final list = tracks.take(6).toList();
                          return SizedBox(
                            height: 181,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenInset,
                              ),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final track = list[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.space3,
                                  ),
                                  child: _MixCard(
                                    index: index,
                                    title: track.title,
                                    artist: track.artist,
                                    onTap: () => _playTrack(
                                        track, quickPicksAsync.value ?? list),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Container(
                            height: 181,
                            width: 184,
                            decoration: BoxDecoration(
                              color: t.raised,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                                  height: 54,
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
                                                color: t.textMuted,
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
      height: 72,
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

class _MixCard extends StatelessWidget {
  const _MixCard({
    required this.index,
    required this.title,
    required this.artist,
    required this.onTap,
  });

  final int index;
  final String title;
  final String artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      width: 184,
      height: 181,
      decoration: BoxDecoration(
        color: t.surface,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 164,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: t.artworkGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _HomeScreenState._waveHeights.map((h) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: Container(
                                width: 4,
                                height: h.toDouble() * 0.9,
                                decoration: BoxDecoration(
                                  color: t.waveform,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            'MIX ${(index + 1).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: t.textPrimary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  artist,
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
        ),
      ),
    );
  }
}
