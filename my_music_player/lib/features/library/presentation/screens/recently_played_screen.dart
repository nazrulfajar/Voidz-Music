import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../providers/recently_played_provider.dart';

enum _RecentAction { clearHistory }

class RecentlyPlayedScreen extends ConsumerWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppColors.of(context);
    final dataAsync = ref.watch(recentlyPlayedProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: AppSpacing.space4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _Header(
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/library');
                      }
                    },
                    onMore: () => _showMoreActions(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Expanded(
                    child: dataAsync.when(
                      data: (data) {
                        if (data.isEmpty) {
                          return _EmptyHistory(
                            onSearch: () => context.go('/search'),
                          );
                        }
                        return _History(
                          data: data,
                          onPlayRecent: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playTrack(
                                  data.tracks.first,
                                  queue: data.tracks,
                                );
                          },
                          onTrackTap: (track) {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playTrack(track, queue: data.tracks);
                          },
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(color: tokens.accent),
                      ),
                      error: (error, stackTrace) => AppErrorState(
                        error: 'Failed to load listening history',
                        onRetry: () => ref.invalidate(recentlyPlayedProvider),
                      ),
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

  Future<void> _showMoreActions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final tokens = AppColors.of(context);
    final action = await showModalBottomSheet<_RecentAction>(
      context: context,
      backgroundColor: tokens.row,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      builder: (sheetContext) {
        final sheetTokens = AppColors.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: sheetTokens.textPrimary,
                ),
                title: Text(
                  'Clear history',
                  style: TextStyle(color: sheetTokens.textPrimary),
                ),
                subtitle: Text(
                  'Remove all listening history',
                  style: TextStyle(color: sheetTokens.textSecondary),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _RecentAction.clearHistory,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (action != _RecentAction.clearHistory || !context.mounted) return;
    await _confirmClearHistory(context, ref);
  }

  Future<void> _confirmClearHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: tokens.row,
          title: Text(
            'Clear listening history?',
            style: TextStyle(color: tokens.textPrimary),
          ),
          content: Text(
            'This permanently removes all play history and recently played '
            'tracks. Listening recap totals will change. Your play counts '
            'are kept.',
            style: TextStyle(color: tokens.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Clear history'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(playlistRepositoryProvider).clearPlayHistory();
    ref.invalidate(recentlyPlayedProvider);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          semanticLabel: 'Back',
          onPressed: onBack,
          iconSize: 18,
          filled: false,
        ),
        Expanded(
          child: Text(
            'Recently played',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.more_horiz_rounded,
          semanticLabel: 'More options',
          onPressed: onMore,
          iconSize: 24,
          filled: false,
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.data,
    required this.onPlayRecent,
    required this.onTrackTap,
  });

  final RecentlyPlayedData data;
  final VoidCallback onPlayRecent;
  final ValueChanged<Track> onTrackTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(
          uniqueTrackCount: data.uniqueTrackCount,
          onPlayRecent: onPlayRecent,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '${data.uniqueTrackCount} unique tracks · last 30 days',
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
        const AppSectionHeader(
          title: 'Tracks',
          padding: EdgeInsets.fromLTRB(
            0,
            AppSpacing.space5,
            0,
            AppSpacing.space2,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.bottomPlayerPadding,
            ),
            itemCount: data.tracks.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.space2),
            itemBuilder: (context, index) {
              final track = data.tracks[index];
              return _RecentTrackRow(
                track: track,
                onTap: () => onTrackTap(track),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.uniqueTrackCount,
    required this.onPlayRecent,
  });

  final int uniqueTrackCount;
  final VoidCallback onPlayRecent;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: tokens.row,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.raised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 24,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LISTENING HISTORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$uniqueTrackCount unique tracks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      'Last 30 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.space12,
            child: FilledButton.icon(
              onPressed: onPlayRecent,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Play recent'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTrackRow extends StatelessWidget {
  const _RecentTrackRow({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: tokens.row,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            AppArtwork(
              localPath: track.localThumbnailPath,
              imageUrl: track.thumbnailUrl,
              size: 44,
              radius: AppRadius.md,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              _formatDuration(track.durationMs),
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.history_rounded,
      title: 'No listening history',
      subtitle: 'Tracks you play will appear here.',
      actionLabel: 'Search music',
      onAction: onSearch,
    );
  }
}

String _formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  return '${duration.inMinutes}:'
      '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}
