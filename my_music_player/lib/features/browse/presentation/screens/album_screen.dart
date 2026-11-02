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

class AlbumScreen extends ConsumerWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailsProvider(albumId));
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: albumAsync.when(
        data: (album) => _buildBody(context, ref, album, theme),
        loading: () => Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
        error: (err, stack) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Gagal memuat album',
          subtitle: '$err',
          actionLabel: 'Coba lagi',
          onAction: () => ref.invalidate(albumDetailsProvider(albumId)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AlbumDetails album,
    ThemeData theme,
  ) {
    final t = AppColors.of(context);
    final palette = ref.watch(paletteProvider(album.thumbnailUrl ?? ''));
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
                if (album.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: album.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  ColoredBox(
                    color: t.surface,
                    child: Icon(
                      Icons.album,
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
                        album.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        album.artist ?? 'Unknown Artist',
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
                        'Album • ${album.year ?? ""} • '
                        '${album.trackCount ?? 0} songs',
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
                              if (album.tracks.isNotEmpty) {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playTrack(
                                      album.tracks.first,
                                      queue: album.tracks,
                                    );
                              }
                            },
                            icon: Icon(Icons.play_arrow, color: t.onAccent),
                            label: Text(
                              'Play',
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
                              if (album.tracks.isNotEmpty) {
                                final shuffled = List.of(album.tracks)
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
                          AppIconButton(
                            icon: Icons.playlist_add,
                            semanticLabel: 'Tambah ke playlist',
                            onPressed: () {
                              if (album.tracks.isNotEmpty) {
                                showAddToPlaylistSheet(
                                  context,
                                  tracks: album.tracks,
                                );
                              }
                            },
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
              final track = album.tracks[index];
              final playerState = ref.watch(playerControllerProvider);
              final isPlaying =
                  playerState.currentTrack?.sourceId == track.sourceId;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                leading: isPlaying
                    ? Icon(
                        Icons.equalizer,
                        color: t.accent,
                        semanticLabel: 'Sedang diputar',
                      )
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: t.textInactive),
                      ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaying ? t.accent : t.textPrimary,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary),
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: t.textSecondary),
                  color: t.raised,
                  tooltip: 'Opsi lagu',
                  onSelected: (value) {
                    if (value == 'add_playlist') {
                      showAddToPlaylistSheet(context, track: track);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'add_playlist',
                      child: Text(
                        'Add to Playlist',
                        style: TextStyle(color: t.textPrimary),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playTrack(track, queue: album.tracks);
                },
              );
            },
            childCount: album.tracks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
