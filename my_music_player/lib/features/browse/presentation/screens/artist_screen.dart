import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/palette_provider.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/browse_models.dart';
import '../providers/browse_provider.dart';

class ArtistScreen extends ConsumerWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailsProvider(artistId));
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: artistAsync.when(
        data: (artist) => _buildBody(context, ref, artist, theme),
        loading: () => Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
        error: (err, stack) => AppEmptyState(
          icon: Icons.error_outline,
          title: l10n.browseArtistLoadError,
          subtitle: '$err',
          actionLabel: l10n.commonTryAgain,
          onAction: () => ref.invalidate(artistDetailsProvider(artistId)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ArtistDetails artist,
    ThemeData theme,
  ) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final cardRowHeight = 140 + MediaQuery.textScalerOf(context).scale(56);
    final palette = ref.watch(paletteProvider(artist.thumbnailUrl ?? ''));
    final dominantColor = palette.value?.dominantColor?.color ?? t.background;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300.0,
          pinned: true,
          backgroundColor: dominantColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (artist.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: artist.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  ColoredBox(
                    color: t.surface,
                    child: Icon(
                      Icons.person,
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
                        artist.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (artist.subscribers != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${artist.subscribers}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: dominantColor != t.background
                                ? dominantColor
                                : t.accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (artist.topSongs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.browseTopSongs,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(playerControllerProvider.notifier)
                            .playTrack(
                              artist.topSongs.first,
                              queue: artist.topSongs,
                            ),
                        icon: Icon(
                          Icons.play_arrow,
                          size: 18,
                          color: t.onAccent,
                        ),
                        label: Text(
                          l10n.commonPlayAll,
                          style: TextStyle(
                            color: t.onAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accent,
                          foregroundColor: t.onAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final s = List.of(artist.topSongs)..shuffle();
                          ref
                              .read(playerControllerProvider.notifier)
                              .playTrack(s.first, queue: s);
                        },
                        icon: Icon(
                          Icons.shuffle,
                          size: 14,
                          color: t.textPrimary,
                        ),
                        label: Text(
                          l10n.commonShuffle,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.textPrimary,
                          side: BorderSide(color: t.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = artist.topSongs[index];
                final playerState = ref.watch(playerControllerProvider);
                final isPlaying =
                    playerState.currentTrack?.sourceId == track.sourceId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: track.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.thumbnailUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: t.surface,
                              child: const Icon(Icons.music_note),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: t.surface,
                            child: const Icon(Icons.music_note),
                          ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying ? t.accent : t.textPrimary,
                      fontWeight:
                          isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary),
                  ),
                  trailing: isPlaying
                      ? Icon(
                          Icons.equalizer,
                          color: t.accent,
                          semanticLabel: l10n.browseNowPlaying,
                        )
                      : ExcludeSemantics(
                          child: Icon(
                            Icons.more_vert,
                            color: t.textSecondary,
                          ),
                        ),
                  onTap: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .playTrack(track, queue: artist.topSongs);
                  },
                );
              },
              childCount:
                  artist.topSongs.length > 5 ? 5 : artist.topSongs.length,
            ),
          ),
        ],
        if (artist.albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.browseAlbums,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardRowHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.albums.length,
                itemBuilder: (context, index) {
                  return _buildAlbumCard(
                    context,
                    artist.albums[index],
                    theme,
                  );
                },
              ),
            ),
          ),
        ],
        if (artist.singles.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.browseSinglesEps,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardRowHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.singles.length,
                itemBuilder: (context, index) {
                  return _buildAlbumCard(
                    context,
                    artist.singles[index],
                    theme,
                  );
                },
              ),
            ),
          ),
        ],
        if (artist.playlists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.browsePlaylists,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardRowHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.playlists.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistCard(
                    context,
                    artist.playlists[index],
                    theme,
                  );
                },
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAlbumCard(
    BuildContext context,
    AlbumItem album,
    ThemeData theme,
  ) {
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        // Premium: canonical push — works from any branch (Home/Search/Library)
        // without tab switch
        context.push('/album/${album.browseId}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: t.raised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: album.thumbnailUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(album.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: album.thumbnailUrl == null
                  ? const Icon(Icons.album, size: 40)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (album.year != null)
              Text(
                album.year!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: t.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(
    BuildContext context,
    PlaylistItem playlist,
    ThemeData theme,
  ) {
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        context.push('/playlist/${playlist.browseId}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: t.raised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: playlist.thumbnailUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          playlist.thumbnailUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: playlist.thumbnailUrl == null
                  ? const Icon(Icons.playlist_play, size: 40)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (playlist.author != null)
              Text(
                playlist.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: t.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
