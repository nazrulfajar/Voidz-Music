import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/search_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../browse/domain/entities/browse_models.dart';
import '../../../player/domain/entities/track.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      // Top filter doesn't support pagination
      if (ref.read(searchFilterProvider) == 'top') return;

      // Reached bottom, increase limit
      final currentLimit = ref.read(searchLimitProvider);
      final searchResults = ref.read(searchResultsProvider);

      if (searchResults.isLoading) return;

      final tracks = searchResults.value ?? [];
      if (tracks.length >= currentLimit && currentLimit < 100) {
        ref.read(searchLimitProvider.notifier).state = currentLimit + 10;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (previous, next) {
      if (previous != next) {
        ref.read(searchLimitProvider.notifier).state = 20;
      }
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      } else if (next.isNotEmpty && _searchController.text != next) {
        _searchController.text = next;
      }
    });

    ref.listen(searchFilterProvider, (previous, next) {
      if (previous != next) {
        ref.read(searchLimitProvider.notifier).state = 20;
      }
    });

    final searchResults = ref.watch(searchResultsProvider);
    final currentFilter = ref.watch(searchFilterProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBase,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBase,
          toolbarHeight: 80, // Taller app bar for search pill
          title: TextField(
            controller: _searchController,
            autofocus: false,
            enabled: isOnline,
            style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    isOnline ? AppColors.textPrimary : AppColors.textTertiary),
            decoration: InputDecoration(
              hintText: isOnline
                  ? 'Search songs, artists...'
                  : 'Search unavailable offline',
              hintStyle: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.accentPrimary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide:
                    const BorderSide(color: AppColors.surfaceOverlay, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide:
                    const BorderSide(color: AppColors.surfaceOverlay, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide:
                    const BorderSide(color: AppColors.accentPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
            onSubmitted: (value) {
              if (isOnline) {
                ref.read(searchQueryProvider.notifier).state = value;
              }
            },
          ),
          bottom: TabBar(
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              color: AppColors.accentPrimary.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.accentPrimary, width: 1),
            ),
            labelColor: AppColors.accentPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.sm),
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            splashBorderRadius: BorderRadius.circular(AppRadius.full),
            onTap: (index) {
              final filter = index == 0
                  ? 'top'
                  : (index == 1
                      ? 'songs'
                      : (index == 2
                          ? 'artists'
                          : (index == 3 ? 'albums' : 'playlists')));
              ref.read(searchFilterProvider.notifier).state = filter;
            },
            tabs: const [
              Tab(text: 'Top'),
              Tab(text: 'Songs'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: !isOnline
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'You are offline',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  if (searchResults.isLoading && !searchResults.hasValue) {
                    return const ShimmerSection(itemCount: 10);
                  }
                  if (searchResults.hasError && !searchResults.hasValue) {
                    return Center(
                      child: Text('Error: ${searchResults.error}',
                          style: const TextStyle(color: AppColors.statusError)),
                    );
                  }

                  final tracks = searchResults.value ?? [];
                  if (tracks.isEmpty) {
                    return _buildHistoryOrEmptyState(context, ref, theme);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.md,
                        bottom: 160),
                    itemCount: tracks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == tracks.length) {
                        return searchResults.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child:
                                    Center(child: CircularProgressIndicator()))
                            : const SizedBox.shrink();
                      }
                      final item = tracks[index];

                      if (currentFilter == 'artists') {
                        if (item is Map<String, dynamic>) {
                          try {
                            final artist = ArtistItem.fromJson(item);
                            return _buildArtistTile(artist, context, theme);
                          } catch (_) {}
                        }
                        return const SizedBox.shrink();
                      } else if (currentFilter == 'albums') {
                        if (item is Map<String, dynamic>) {
                          try {
                            final album = AlbumItem.fromJson(item);
                            return _buildAlbumTile(album, context, theme);
                          } catch (_) {}
                        }
                        return const SizedBox.shrink();
                      } else if (currentFilter == 'playlists') {
                        if (item is Map<String, dynamic>) {
                          try {
                            final playlist = PlaylistItem.fromJson(item);
                            return _buildPlaylistTile(playlist, context, theme);
                          } catch (_) {}
                        }
                        return const SizedBox.shrink();
                      } else if (currentFilter == 'top') {
                        if (item is Map<String, dynamic> &&
                            item.containsKey('result_type')) {
                          final type = item['result_type'];
                          if (type == 'artist') {
                            return _buildArtistTile(
                                ArtistItem.fromJson(item), context, theme);
                          } else if (type == 'album') {
                            return _buildAlbumTile(
                                AlbumItem.fromJson(item), context, theme);
                          } else {
                            // type == 'song'
                            final track = Track.fromJson(item);
                            return _buildTrackTile(
                                track, tracks, context, theme, ref);
                          }
                        }
                        return const SizedBox.shrink();
                      } else {
                        // currentFilter == 'songs'
                        if (item is Track) {
                          return _buildTrackTile(
                              item, tracks, context, theme, ref);
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildArtistTile(
      ArtistItem artist, BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          textColor: AppColors.textPrimary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: artist.thumbnailUrl != null
                ? CachedNetworkImageProvider(artist.thumbnailUrl!)
                : null,
            child:
                artist.thumbnailUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(artist.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          onTap: () {
            context.push('/search/artist/${artist.browseId}');
          },
        ),
      ),
    );
  }

  Widget _buildAlbumTile(
      AlbumItem album, BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          textColor: AppColors.textPrimary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              image: album.thumbnailUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(album.thumbnailUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: album.thumbnailUrl == null ? const Icon(Icons.album) : null,
          ),
          title: Text(album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          subtitle: Text('${album.artist} • ${album.year ?? ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          onTap: () {
            context.push('/search/album/${album.browseId}');
          },
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(
      PlaylistItem playlist, BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          textColor: AppColors.textPrimary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              image: playlist.thumbnailUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(playlist.thumbnailUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: playlist.thumbnailUrl == null
                ? const Icon(Icons.playlist_play)
                : null,
          ),
          title: Text(playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          subtitle: Text(
              '${playlist.author ?? "Unknown"} • ${playlist.itemCount ?? "0"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          onTap: () {
            context.push('/search/playlist/${playlist.browseId}');
          },
        ),
      ),
    );
  }

  Widget _buildTrackTile(dynamic track, List<dynamic> allTracks, BuildContext context, ThemeData theme, WidgetRef ref) {
    // Premium: queue = lagu relevan dari lagu yang diputar (up-next), bukan list hasil pencarian
    // Ponytail: play single + biarkan auto-queue (_fetchAndAppendAutoQueue) isi relevan via getUpNext
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        final isPlaying = playerState.currentTrack?.sourceId == track.sourceId;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              tileColor: isPlaying ? AppColors.surfaceHover : null,
              hoverColor: AppColors.surfaceHover,
              onTap: () {
                ref.read(playerControllerProvider.notifier).playTrack(track as Track, queue: [track as Track]);
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: track.localThumbnailPath != null
                    ? Image.file(File(track.localThumbnailPath!), width: 48, height: 48, fit: BoxFit.cover, cacheWidth: 100, errorBuilder: (_, __, ___) => track.thumbnailUrl != null ? Image(image: CachedNetworkImageProvider(track.thumbnailUrl!), width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary))) : Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary)))
                    : track.thumbnailUrl != null ? CachedNetworkImage(imageUrl: track.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover, memCacheWidth: 100, placeholder: (_, __) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay), errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary))) : Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.music_note, color: AppColors.textTertiary)),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isPlaying ? FontWeight.bold : FontWeight.w500,
                        color: isPlaying
                            ? AppColors.accentPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (track.isCached) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.offline_pin,
                        color: AppColors.statusSuccess, size: 16),
                  ],
                ],
              ),
              subtitle: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              trailing: isPlaying
                  ? const Icon(Icons.equalizer, color: AppColors.accentPrimary)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryOrEmptyState(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final query = ref.read(searchQueryProvider);
    if (query.isNotEmpty) {
      return Center(
        child: Text(
          'No results found for "$query"',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.search_rounded,
                      size: 80, color: AppColors.accentPrimary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'What do you want to listen to?',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Search for artists, songs, or albums',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(searchHistoryControllerProvider).clearHistory();
                    },
                    child: const Text('Clear All',
                        style: TextStyle(color: AppColors.accentPrimary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 160),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history,
                        color: AppColors.textSecondary),
                    title: Text(item.query, style: theme.textTheme.bodyLarge),
                    trailing: IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textTertiary, size: 20),
                      onPressed: () {
                        ref
                            .read(searchHistoryControllerProvider)
                            .deleteHistory(item.id);
                      },
                    ),
                    onTap: () {
                      ref.read(searchQueryProvider.notifier).state = item.query;
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
