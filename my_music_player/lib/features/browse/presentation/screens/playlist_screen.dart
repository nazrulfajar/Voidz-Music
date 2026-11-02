import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/palette_provider.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/browse_models.dart';
import '../providers/browse_provider.dart';

class PlaylistScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailsProvider(playlistId));
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: playlistAsync.when(
        data: (playlist) => _buildBody(context, ref, playlist, theme),
        loading: () => Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
        error: (err, stack) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Gagal memuat playlist',
          subtitle: '$err',
          actionLabel: 'Coba lagi',
          onAction: () => ref.invalidate(playlistDetailsProvider(playlistId)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PlaylistDetails playlist,
    ThemeData theme,
  ) {
    final t = AppColors.of(context);
    final palette = ref.watch(paletteProvider(playlist.thumbnailUrl ?? ''));
    final dominantColor = palette.value?.dominantColor?.color ?? t.background;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350.0,
          pinned: true,
          backgroundColor: dominantColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (playlist.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: playlist.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  ColoredBox(
                    color: t.surface,
                    child: Icon(
                      Icons.playlist_play,
                      size: 80,
                      color: t.textSecondary,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dominantColor.withValues(alpha: 0.4),
                        t.background.withValues(alpha: 0.8),
                        t.background,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        playlist.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        playlist.author ?? 'Unknown Author',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: dominantColor != t.background
                              ? dominantColor
                              : t.accent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Playlist • ${playlist.trackCount ?? 0} songs',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: t.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (playlist.tracks.isNotEmpty) {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playTrack(
                                      playlist.tracks.first,
                                      queue: playlist.tracks,
                                    );
                              }
                            },
                            icon: Icon(Icons.play_arrow, color: t.onAccent),
                            label: Text(
                              'Play All',
                              style: TextStyle(
                                color: t.onAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.accent,
                              foregroundColor: t.onAccent,
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (playlist.tracks.isNotEmpty) {
                                final shuffled = List.of(playlist.tracks)
                                  ..shuffle();
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playTrack(
                                      shuffled.first,
                                      queue: shuffled,
                                    );
                              }
                            },
                            icon: Icon(Icons.shuffle, color: t.textPrimary),
                            label: Text(
                              'Acak',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: t.textPrimary,
                              side: BorderSide(color: t.border),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == playlist.tracks.length) {
                return const SizedBox(height: 120); // Bottom padding
              }
              final track = playlist.tracks[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: CachedNetworkImage(
                    imageUrl: track.thumbnailUrl ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => ColoredBox(
                      color: t.surface,
                      child: Icon(
                        Icons.music_note,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                subtitle: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary),
                ),
                trailing: AppIconButton(
                  icon: Icons.more_vert,
                  semanticLabel: 'Opsi lagu',
                  iconSize: 20,
                  filled: false,
                  onPressed: () {
                    showAddToPlaylistSheet(context, track: track);
                  },
                ),
                onTap: () {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playTrack(track, queue: playlist.tracks);
                },
              );
            },
            childCount: playlist.tracks.length + 1,
          ),
        ),
      ],
    );
  }
}
