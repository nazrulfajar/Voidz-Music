import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../providers/browse_provider.dart';
import '../widgets/browse_source_card.dart';

/// Browse hub (design frame 11), adapted to the on-device YouTube Music
/// resolver (ADR-014).
///
/// Only sources the app really owns are shown: YouTube Music search and the
/// local device library. Recently played comes from the existing track
/// repository. There is no feed endpoint and no obsolete source.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppColors.of(context);
    final recentlyPlayed = ref.watch(browseRecentlyPlayedProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space3,
                AppSpacing.space4,
                AppSpacing.bottomPlayerPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/search');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          'Browse',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  BrowseSourceCard(
                    icon: Icons.music_video_rounded,
                    title: 'YouTube Music',
                    subtitle: 'Search songs, artists, and albums',
                    semanticLabel: 'Search YouTube Music',
                    onTap: () => context.go('/search'),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  BrowseSourceCard(
                    icon: Icons.phone_android_rounded,
                    title: 'Device songs',
                    subtitle: 'Play audio stored on this device',
                    semanticLabel: 'Open device songs',
                    onTap: () => context.go('/library/device-songs'),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  Text(
                    'Recently played',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  recentlyPlayed.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.history_rounded,
                          title: 'Nothing played yet',
                          subtitle: 'Tracks you play will appear here',
                        );
                      }
                      return Column(
                        children: [
                          for (final track in tracks)
                            _RecentTrackRow(
                              track: track,
                              durationLabel: _formatDuration(track.durationMs),
                              onTap: () => ref
                                  .read(playerControllerProvider.notifier)
                                  .playTrack(track, queue: tracks),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.space6),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load recently played',
                      subtitle: 'Check your library and try again',
                      actionLabel: 'Try again',
                      onAction: () =>
                          ref.invalidate(browseRecentlyPlayedProvider),
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

class _RecentTrackRow extends StatelessWidget {
  const _RecentTrackRow({
    required this.track,
    required this.durationLabel,
    required this.onTap,
  });

  final Track track;
  final String durationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return Semantics(
      button: true,
      label: 'Play ${track.title} by ${track.artist}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space1,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  AppArtwork(
                    localPath: track.localThumbnailPath,
                    imageUrl: track.thumbnailUrl,
                    size: 48,
                    radius: AppRadius.md,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
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
