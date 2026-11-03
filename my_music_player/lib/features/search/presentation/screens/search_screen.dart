import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../browse/domain/entities/browse_models.dart';
import '../../../browse/presentation/widgets/browse_source_card.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../providers/search_provider.dart';

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

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '—';
    final d = Duration(milliseconds: ms);
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '${d.inHours}:$m:$s';
    }
    return '${d.inMinutes}:$s';
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
      setState(() {});
    });

    ref.listen(searchFilterProvider, (previous, next) {
      if (previous != next) {
        ref.read(searchLimitProvider.notifier).state = 20;
      }
    });

    final searchState = ref.watch(searchStateProvider);
    final currentFilter = ref.watch(searchFilterProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    final filters = <(String, String)>[
      (l10n.searchFilterAll, 'top'),
      (l10n.searchFilterSongs, 'songs'),
      (l10n.searchFilterArtists, 'artists'),
      (l10n.searchFilterAlbums, 'albums'),
      (l10n.searchFilterPlaylists, 'playlists'),
    ];

    String headerLabel() {
      switch (currentFilter) {
        case 'top':
          return l10n.searchHeaderTop;
        case 'songs':
          return l10n.searchFilterSongs;
        case 'artists':
          return l10n.searchFilterArtists;
        case 'albums':
          return l10n.searchFilterAlbums;
        case 'playlists':
          return l10n.searchFilterPlaylists;
        default:
          return l10n.searchHeaderResults;
      }
    }

    String resultCountLabel(int count) {
      return switch (currentFilter) {
        'songs' => l10n.commonSongCount(count),
        'artists' => l10n.searchArtistsCount(count),
        'albums' => l10n.searchAlbumsCount(count),
        'playlists' => l10n.searchPlaylistsCount(count),
        _ => l10n.searchResultsCount(count),
      };
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space3,
                    AppSpacing.space4,
                    AppSpacing.space2,
                  ),
                  child: _buildSearchField(isOnline, t, l10n),
                ),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                    ),
                    itemCount: filters.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.space2),
                    itemBuilder: (context, index) {
                      final (label, value) = filters[index];
                      return _buildFilterChip(
                        label: label,
                        value: value,
                        selected: currentFilter == value,
                        tokens: t,
                        l10n: l10n,
                        onTap: () => ref
                            .read(searchFilterProvider.notifier)
                            .state = value,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Expanded(
                  child: !isOnline
                      ? _buildOfflineState(l10n)
                      : switch (searchState) {
                          SearchIdle() => _buildIdleState(context, ref, t),
                          SearchLoading() => const ShimmerSection(itemCount: 6),
                          SearchEmpty(:final query) =>
                            _buildNoResultsState(query, l10n),
                          SearchError(:final error) =>
                            _buildErrorState(error, ref, l10n),
                          SearchData(
                            :final items,
                            :final isLoadingMore,
                          ) =>
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.space4,
                                AppSpacing.space2,
                                AppSpacing.space4,
                                AppSpacing.bottomPlayerPadding,
                              ),
                              itemCount: items.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.space2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            headerLabel().toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 1.1,
                                              color: t.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.space2,
                                        ),
                                        Flexible(
                                          child: Text(
                                            resultCountLabel(
                                              items.length,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: t.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (index == items.length + 1) {
                                  return isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(
                                            AppSpacing.space4,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }
                                final item = items[index - 1];

                                if (currentFilter == 'artists') {
                                  if (item is Map<String, dynamic>) {
                                    try {
                                      final artist = ArtistItem.fromJson(item);
                                      return _buildArtistTile(
                                        artist,
                                        context,
                                        t,
                                      );
                                    } catch (_) {}
                                  }
                                  return const SizedBox.shrink();
                                } else if (currentFilter == 'albums') {
                                  if (item is Map<String, dynamic>) {
                                    try {
                                      final album = AlbumItem.fromJson(item);
                                      return _buildAlbumTile(
                                        album,
                                        context,
                                        t,
                                      );
                                    } catch (_) {}
                                  }
                                  return const SizedBox.shrink();
                                } else if (currentFilter == 'playlists') {
                                  if (item is Map<String, dynamic>) {
                                    try {
                                      final playlist =
                                          PlaylistItem.fromJson(item);
                                      return _buildPlaylistTile(
                                        playlist,
                                        context,
                                        t,
                                      );
                                    } catch (_) {}
                                  }
                                  return const SizedBox.shrink();
                                } else if (currentFilter == 'top') {
                                  if (item is Map<String, dynamic> &&
                                      item.containsKey('result_type')) {
                                    final type = item['result_type'];
                                    if (type == 'artist') {
                                      return _buildArtistTile(
                                        ArtistItem.fromJson(item),
                                        context,
                                        t,
                                      );
                                    } else if (type == 'album') {
                                      return _buildAlbumTile(
                                        AlbumItem.fromJson(item),
                                        context,
                                        t,
                                      );
                                    } else if (type == 'playlist') {
                                      return _buildPlaylistTile(
                                        PlaylistItem.fromJson(item),
                                        context,
                                        t,
                                      );
                                    } else {
                                      final track = Track.fromJson(item);
                                      return _buildTrackTile(
                                        track,
                                        context,
                                        t,
                                        ref,
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                } else {
                                  if (item is Track) {
                                    return _buildTrackTile(
                                      item,
                                      context,
                                      t,
                                      ref,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState(AppLocalizations l10n) {
    return AppStatePanel(
      variant: AppStateVariant.offline,
      title: l10n.searchOfflineTitle,
      message: l10n.searchOfflineMessage,
    );
  }

  Widget _buildErrorState(
    Object? error,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return AppErrorState(
      error: l10n.searchError,
      cause: error,
      onRetry: () => ref.invalidate(searchResultsProvider),
    );
  }

  Widget _buildNoResultsState(String query, AppLocalizations l10n) {
    return AppStatePanel(
      variant: AppStateVariant.empty,
      icon: Icons.search_off_rounded,
      title: l10n.searchNoResultsTitle,
      message: l10n.searchNoResultsMessage(query),
      actionLabel: l10n.searchClear,
      onAction: _clearSearch,
    );
  }

  Widget _buildIdleState(
      BuildContext context, WidgetRef ref, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.bottomPlayerPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppStatePanel(
                  variant: AppStateVariant.empty,
                  icon: Icons.search_rounded,
                  title: l10n.searchIdleTitle,
                  message: l10n.searchIdleMessage,
                ),
                const SizedBox(height: AppSpacing.space8),
                _buildBrowseSection(context, t),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomPlayerPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: l10n.searchRecentTitle,
                actionLabel: l10n.searchClearHistory,
                onAction: () =>
                    ref.read(searchHistoryControllerProvider).clearHistory(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                ),
                child: Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: history.map((item) {
                    return _buildRecentChip(
                      query: item.query,
                      id: item.id,
                      ref: ref,
                      tokens: t,
                      l10n: l10n,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              _buildBrowseSection(context, t),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBrowseSection(BuildContext context, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.searchBrowseBySource,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          BrowseSourceCard(
            key: const ValueKey('search-browse-entry'),
            glassQuality: GlassQuality.frosted,
            icon: Icons.travel_explore_rounded,
            title: l10n.searchBrowseSources,
            subtitle: l10n.searchBrowseSourcesSubtitle,
            semanticLabel: l10n.searchBrowseBySource,
            onTap: () => context.push('/search/browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    bool isOnline,
    AppColorTokens t,
    AppLocalizations l10n,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 47),
            child: GlassSurface.card(
              key: const Key('search-field-glass'),
              quality: GlassQuality.blurred,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: TextField(
                controller: _searchController,
                enabled: isOnline,
                style: TextStyle(
                  fontSize: 14,
                  color: isOnline ? t.textPrimary : t.textMuted,
                ),
                decoration: InputDecoration(
                  hintText: isOnline ? l10n.searchHint : l10n.searchHintOffline,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: t.textMuted,
                  ),
                  filled: false,
                  isDense: true,
                  prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: t.textSecondary,
                    ),
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : const SizedBox(width: 48),
                  suffixIconConstraints: const BoxConstraints(minWidth: 48),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: t.focusedBorder),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  if (isOnline) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  }
                },
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Positioned(
              right: 0,
              child: Semantics(
                container: true,
                button: true,
                label: l10n.searchClear,
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: l10n.searchClear,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: t.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: _clearSearch,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required AppColorTokens tokens,
    required AppLocalizations l10n,
    required VoidCallback onTap,
  }) {
    final glass = AppGlass.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.searchFilterSemantics(label),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Container(
                key: ValueKey('search-filter-chip-$value'),
                constraints: const BoxConstraints(minHeight: 29),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? glass.chipSelectedFill : glass.chipSubtleFill,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: selected
                        ? glass.chipSelectedBorder
                        : glass.chipSubtleBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChip({
    required String query,
    required int id,
    required WidgetRef ref,
    required AppColorTokens tokens,
    required AppLocalizations l10n,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: GlassSurface.card(
        key: ValueKey('search-recent-glass-$id'),
        quality: GlassQuality.frosted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Semantics(
                  button: true,
                  label: l10n.searchRecentQuerySemantics(query),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () =>
                        ref.read(searchQueryProvider.notifier).state = query,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.space3,
                          right: AppSpacing.space2,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                label: l10n.searchRemoveRecentSemantics(query),
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: l10n.searchRemoveRecentSemantics(query),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: tokens.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: () => ref
                        .read(searchHistoryControllerProvider)
                        .deleteHistory(id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistTile(
      ArtistItem artist, BuildContext context, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      button: true,
      label: l10n.searchSemanticsArtist(artist.name),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space2),
        child: GlassSurface.card(
          key: ValueKey('search-artist-glass-${artist.browseId}'),
          quality: GlassQuality.frosted,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                context.push('/search/artist/${artist.browseId}');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          width: 48,
                          height: 48,
                          color: t.raised,
                          child: artist.thumbnailUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: artist.thumbnailUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.person_rounded,
                                    color: t.textSecondary,
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  color: t.textSecondary,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ).copyWith(color: t.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist.subscribers == null
                                  ? l10n.commonArtist
                                  : '${l10n.commonArtist} • '
                                      '${artist.subscribers}',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumTile(
      AlbumItem album, BuildContext context, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    final artist = album.artist == null || album.artist!.isEmpty
        ? l10n.browseUnknownArtist
        : album.artist!;
    return Semantics(
      container: true,
      button: true,
      label: l10n.searchSemanticsAlbum(album.title, artist),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space2),
        child: GlassSurface.card(
          key: ValueKey('search-album-glass-${album.browseId}'),
          quality: GlassQuality.frosted,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                context.push('/search/album/${album.browseId}');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      AppArtwork(
                        imageUrl: album.thumbnailUrl,
                        size: 48,
                        radius: AppRadius.md,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                l10n.commonAlbum,
                                artist,
                                if (album.year != null &&
                                    album.year!.isNotEmpty)
                                  album.year!,
                              ].join(' • '),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(
      PlaylistItem playlist, BuildContext context, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    final author = playlist.author ?? l10n.commonUnknown;
    return Semantics(
      container: true,
      button: true,
      label: l10n.searchSemanticsPlaylist(playlist.title, author),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space2),
        child: GlassSurface.card(
          key: ValueKey('search-playlist-glass-${playlist.browseId}'),
          quality: GlassQuality.frosted,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                context.push('/search/playlist/${playlist.browseId}');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      AppArtwork(
                        imageUrl: playlist.thumbnailUrl,
                        size: 48,
                        radius: AppRadius.md,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.commonPlaylist} • $author • '
                              '${playlist.itemCount ?? '0'}',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTile(
    Track track,
    BuildContext context,
    AppColorTokens t,
    WidgetRef ref,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context);
        final playerState = ref.watch(playerControllerProvider);
        final isPlaying = playerState.currentTrack?.sourceId == track.sourceId;

        return Semantics(
          container: true,
          button: true,
          label: l10n.searchSemanticsTrack(track.title, track.artist),
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GlassSurface.card(
              key: ValueKey('search-track-glass-${track.sourceId}'),
              quality: GlassQuality.frosted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .playTrack(track, queue: [track]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: isPlaying ? t.raised : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: t.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (track.isCached) ...[
                                    const SizedBox(width: AppSpacing.space1),
                                    Icon(
                                      Icons.offline_pin,
                                      size: 16,
                                      color: t.textSecondary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
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
                        if (isPlaying)
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 18,
                            color: t.textPrimary,
                          )
                        else
                          Text(
                            _formatDuration(track.durationMs),
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
          ),
        );
      },
    );
  }
}
