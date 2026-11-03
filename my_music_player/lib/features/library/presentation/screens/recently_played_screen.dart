import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_chrome_insets.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/glass_surface.dart';
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
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(recentlyPlayedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                        error: l10n.recentlyPlayedLoadError,
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.recentlyPlayedClear,
                  style: TextStyle(color: sheetTokens.textPrimary),
                ),
                subtitle: Text(
                  l10n.recentlyPlayedClearSubtitle,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: tokens.row,
          title: Text(
            l10n.recentlyPlayedClearTitle,
            style: TextStyle(color: tokens.textPrimary),
          ),
          content: Text(
            l10n.recentlyPlayedClearBody,
            style: TextStyle(color: tokens.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                l10n.commonCancelAction,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.recentlyPlayedClear),
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          semanticLabel: l10n.commonBack,
          onPressed: onBack,
          iconSize: 18,
          filled: false,
        ),
        Expanded(
          child: Text(
            l10n.libraryRecentlyPlayed,
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
          semanticLabel: l10n.commonMoreOptions,
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
    final l10n = AppLocalizations.of(context);
    // TASK-042: at 200% scale the summary alone is taller than the viewport
    // remainder, so the whole history becomes one scrollable surface. Normal
    // scale keeps the fixed summary + scrolling track list.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;

    final summary = _SummaryCard(
      uniqueTrackCount: data.uniqueTrackCount,
      onPlayRecent: onPlayRecent,
    );
    final summaryText = Text(
      l10n.recentlyPlayedSummary(data.uniqueTrackCount),
      style: TextStyle(fontSize: 12, color: tokens.textSecondary),
    );
    final section = AppSectionHeader(
      title: l10n.recentlyPlayedTracks,
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSpacing.space5,
        0,
        AppSpacing.space2,
      ),
    );

    if (largeText) {
      return ListView(
        padding: EdgeInsets.only(
          bottom: AppChromeInsets.bottomOf(context),
        ),
        children: [
          summary,
          const SizedBox(height: AppSpacing.space2),
          summaryText,
          section,
          for (var index = 0; index < data.tracks.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.space2),
            _RecentTrackRow(
              track: data.tracks[index],
              onTap: () => onTrackTap(data.tracks[index]),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        const SizedBox(height: AppSpacing.space2),
        summaryText,
        section,
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(
              bottom: AppChromeInsets.bottomOf(context),
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
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: GlassSurface.card(
        key: const Key('recently-played-summary-glass'),
        quality: GlassQuality.blurred,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.space4),
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
                        l10n.recentlyPlayedOverline,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.recentlyPlayedUniqueCount(uniqueTrackCount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.recentlyPlayedWindow,
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
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.space12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPlayRecent,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.recentlyPlayedPlay),
                ),
              ),
            ),
          ],
        ),
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
    return GlassSurface.card(
      key: ValueKey('recently-played-row-glass-${track.sourceId}'),
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.trackRowHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.history_rounded,
      title: l10n.recentlyPlayedEmptyTitle,
      subtitle: l10n.recentlyPlayedEmptySubtitle,
      actionLabel: l10n.librarySearchMusic,
      onAction: onSearch,
    );
  }
}

String _formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  return '${duration.inMinutes}:'
      '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}
