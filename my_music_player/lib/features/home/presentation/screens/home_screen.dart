import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_chrome_insets.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
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
  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
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
    final l10n = AppLocalizations.of(context);
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

    final recentTracks = recentlyPlayedAsync.valueOrNull ?? const <Track>[];
    final cardTrack = playerState.currentTrack ??
        (recentTracks.isNotEmpty ? recentTracks.first : null);
    final isCardCurrent = cardTrack != null &&
        playerState.currentTrack?.sourceId == cardTrack.sourceId;
    final cardQueue = isCardCurrent ? playerState.currentQueue : recentTracks;
    final isCardFinished = isCardCurrent &&
        playerState.duration > Duration.zero &&
        playerState.position >= playerState.duration;
    final isCardPlaying =
        isCardCurrent && playerState.isPlaying && !isCardFinished;
    final cardProgress =
        isCardCurrent && playerState.duration.inMilliseconds > 0
            ? (playerState.position.inMilliseconds /
                    playerState.duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

    void onCardTap() {
      if (cardTrack == null) return;
      final controller = ref.read(playerControllerProvider.notifier);
      if (isCardCurrent && !isCardFinished) {
        controller.togglePlayPause();
      } else {
        controller.playTrack(cardTrack, queue: cardQueue);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: t.accent,
          backgroundColor: t.field,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: AppChromeInsets.bottomOf(context),
            ),
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
                                _greeting(l10n),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: t.textPrimary,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                            _HomeSettingsButton(
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ),

                      // Offline banner
                      if (!isOnline)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.screenInset,
                            AppSpacing.space2,
                            AppSpacing.screenInset,
                            AppSpacing.space2,
                          ),
                          child: AppOfflineBanner(),
                        ),

                      // Continue listening / now listening section.
                      if (cardTrack != null)
                        AppSectionHeader(
                          title: isCardPlaying
                              ? l10n.homeNowListening
                              : l10n.homeContinueListening,
                        ),
                      if (cardTrack != null)
                        _ContinueListeningCard(
                          track: cardTrack,
                          isCurrent: isCardCurrent,
                          isPlaying: isCardPlaying,
                          progress: cardProgress,
                          onTap: onCardTap,
                        )
                      else
                        recentlyPlayedAsync.when(
                          data: (_) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenInset,
                            ),
                            child: AppEmptyState(
                              compact: true,
                              icon: Icons.history_rounded,
                              title: l10n.homeNoRecentTitle,
                              actionLabel: l10n.homeSearchMusic,
                              onAction: () => context.go('/search'),
                            ),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenInset,
                            ),
                            child: ShimmerContinueCard(),
                          ),
                          error: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenInset,
                            ),
                            child: Text(
                              l10n.homeLoadError,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: t.textSecondary,
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
                                title: l10n.homeQuickDownloaded,
                                meta: l10n.homeOfflineCache,
                                onTap: () => context.push('/downloaded'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.folder_outlined,
                                title: l10n.homeDeviceSongs,
                                meta: l10n.homeOnThisDevice,
                                onTap: () => context.push('/device-songs'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // Daily mix section: five fixed mood cards.
                      AppSectionHeader(title: l10n.dailyMixLabel),
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
                        AppSectionHeader(
                          title: l10n.homeRecentlyPlayed,
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
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minHeight: 54),
                                  child: GlassSurface.card(
                                    key: ValueKey(
                                      'home-recent-${track.sourceId}',
                                    ),
                                    quality: GlassQuality.frosted,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
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
                                                _formatDuration(
                                                    track.durationMs),
                                                style: theme
                                                    .textTheme.labelSmall
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
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const ShimmerSection(itemCount: 3),
                        error: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenInset,
                          ),
                          child: Text(
                            l10n.homeLoadError,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.textSecondary,
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

/// Continue/now-listening card. Receives immutable playback state and a single
/// callback; it never reads the player controller itself.
class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard({
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
  });

  final Track track;
  final bool isCurrent;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final actionLabel = isPlaying
        ? l10n.homePauseTrack(track.title)
        : l10n.homePlayTrack(track.title);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 98),
        child: GlassSurface.card(
          key: const Key('home-continue-glass'),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    onTap: onTap,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    AppArtwork(
                      localPath: track.localThumbnailPath,
                      imageUrl: track.thumbnailUrl,
                      size: 68,
                      radius: AppRadius.artworkSmall,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${track.artist} · ${track.source.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 198),
                            child: Container(
                              height: 3,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: tokens.track,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: isCurrent
                                  ? FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(color: tokens.accent),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Semantics(
                      button: true,
                      label: actionLabel,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: tokens.accent,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              color: tokens.onAccent,
                              size: 24,
                            ),
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
      ),
    );
  }
}

/// 48dp Home settings control on the glass chrome recipe.
///
/// Frosted instead of blurred: the shell already spends its blur budget on the
/// navigation/mini-player and the Continue card.
class _HomeSettingsButton extends StatelessWidget {
  const _HomeSettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).settingsTitle,
      enabled: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: GlassSurface.chrome(
          key: const Key('home-settings-glass'),
          quality: GlassQuality.frosted,
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Icon(
                Icons.settings_outlined,
                size: 20,
                color: tokens.textPrimary,
              ),
            ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: GlassSurface.card(
        quality: GlassQuality.frosted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
      ),
    );
  }
}
