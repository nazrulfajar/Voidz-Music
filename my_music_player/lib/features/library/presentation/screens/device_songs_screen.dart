import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_list_tile.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';

enum DeviceFilter { songs, artists, albums }

class DeviceSongsScreen extends ConsumerStatefulWidget {
  const DeviceSongsScreen({super.key});

  @override
  ConsumerState<DeviceSongsScreen> createState() => _DeviceSongsScreenState();
}

class _DeviceSongsScreenState extends ConsumerState<DeviceSongsScreen> {
  String _query = '';
  DeviceFilter _filter = DeviceFilter.songs;
  String? _selectedArtist;
  String? _selectedAlbumKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceScanControllerProvider.notifier).checkPermissionStatus();
    });
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatTotalDuration(int ms, AppLocalizations l10n) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      return m == 0
          ? l10n.commonDurationHours(h)
          : l10n.playlistsDurationHoursMinutes(h, m);
    }
    return l10n.playlistsDurationMinutes(m);
  }

  String _formatBitrate(int? kbps, String? fmt) {
    final parts = <String>[];
    if (fmt != null && fmt.isNotEmpty) parts.add(fmt.toUpperCase());
    if (kbps != null && kbps > 0) parts.add('$kbps kbps');
    return parts.join(' • ');
  }

  String _fmtSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Map<String, List<Track>> _groupByArtist(
    List<Track> tracks,
    AppLocalizations l10n,
  ) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final key =
          t.artist.trim().isEmpty ? l10n.browseUnknownArtist : t.artist.trim();
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Map<String, List<Track>> _groupByAlbum(
    List<Track> tracks,
    AppLocalizations l10n,
  ) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final album = (t.album == null || t.album!.trim().isEmpty)
          ? l10n.commonUnknownAlbum
          : t.album!.trim();
      final artist =
          t.artist.trim().isEmpty ? l10n.browseUnknownArtist : t.artist.trim();
      final key = '$album|||$artist';
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  List<Track> _sortedAlbumTracks(List<Track> tracks) {
    final list = List<Track>.of(tracks);
    list.sort((a, b) {
      final da = a.discNumber ?? 0;
      final db = b.discNumber ?? 0;
      if (da != db) return da.compareTo(db);
      final ta = a.trackNumber;
      final tb = b.trackNumber;
      if (ta != null && tb != null && ta != tb) return ta.compareTo(tb);
      if (ta != null && tb == null) return -1;
      if (ta == null && tb != null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }

  List<Track> _filterSongs(List<Track> tracks) {
    if (_query.isEmpty) return tracks;
    final q = _query.toLowerCase();
    return tracks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          (t.album?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final deviceAsync = ref.watch(deviceSongsProvider);
    final scanState = ref.watch(deviceScanControllerProvider);
    final playerState = ref.watch(playerControllerProvider);
    final hasDrill = _selectedArtist != null || _selectedAlbumKey != null;
    final isAlbumDetail = _selectedAlbumKey != null;
    final isArtistAlbums = _selectedArtist != null && _selectedAlbumKey == null;
    return PopScope(
      canPop: !hasDrill,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && hasDrill) {
          setState(() {
            if (_selectedAlbumKey != null) {
              _selectedAlbumKey = null;
            } else if (_selectedArtist != null) {
              _selectedArtist = null;
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: textScaler.scale(56),
          leading: hasDrill
              ? Center(
                  child: AppIconButton(
                    icon: Icons.arrow_back,
                    semanticLabel: l10n.commonBack,
                    filled: false,
                    onPressed: () => setState(() {
                      if (_selectedAlbumKey != null) {
                        _selectedAlbumKey = null;
                      } else {
                        _selectedArtist = null;
                      }
                    }),
                  ),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAlbumDetail
                    ? _selectedAlbumKey!.split('|||').first
                    : (_selectedArtist ?? l10n.libraryDeviceSongs),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              deviceAsync.when(
                data: (tracks) {
                  if (isAlbumDetail) {
                    final list =
                        _groupByAlbum(tracks, l10n)[_selectedAlbumKey] ?? [];
                    if (list.isEmpty) return const SizedBox.shrink();
                    final totalMs =
                        list.fold<int>(0, (s, t) => s + t.durationMs);
                    return Text(
                      '${l10n.commonSongCount(list.length)} • '
                      '${_formatTotalDuration(totalMs, l10n)} • '
                      '${list.first.artist}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  if (isArtistAlbums) {
                    final albumCount = _groupByAlbum(tracks, l10n)
                        .keys
                        .where((k) => k.split('|||').last == _selectedArtist)
                        .length;
                    final songCount =
                        tracks.where((t) => t.artist == _selectedArtist).length;
                    return Text(
                      '${l10n.commonAlbumCount(albumCount)} • '
                      '${l10n.commonSongCount(songCount)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  int bytes = 0;
                  for (final t in tracks) {
                    bytes += t.fileSizeBytes ?? 0;
                  }
                  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
                  return Text(
                    '${l10n.commonSongCount(tracks.length)} • $mb MB',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: t.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                loading: () => Text(
                  l10n.commonLoading,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: t.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            if (scanState.isScanning)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: t.accent,
                  ),
                ),
              )
            else
              AppIconButton(
                icon: Icons.refresh,
                semanticLabel: l10n.deviceSongsRescan,
                filled: false,
                onPressed: () =>
                    ref.read(deviceScanControllerProvider.notifier).scan(),
              ),
          ],
        ),
        body: scanState.permissionDenied
            ? AppStatePanel(
                variant: AppStateVariant.permission,
                title: l10n.deviceSongsPermissionTitle,
                message: l10n.deviceSongsPermissionMessage,
                actionLabel: scanState.permanentlyDenied
                    ? l10n.deviceSongsOpenSettings
                    : l10n.deviceSongsAllowAccess,
                actionIcon: scanState.permanentlyDenied
                    ? Icons.settings_rounded
                    : Icons.check_rounded,
                onAction: () async {
                  if (scanState.permanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await ref
                        .read(deviceScanControllerProvider.notifier)
                        .scan();
                  }
                },
                footnote: l10n.deviceSongsPermissionFootnote,
              )
            : RefreshIndicator(
                color: t.accent,
                backgroundColor: t.surface,
                onRefresh: () async => await ref
                    .read(deviceScanControllerProvider.notifier)
                    .scan(),
                child: CustomScrollView(
                  slivers: [
                    // Search — glass over the aurora
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: GlassSurface.card(
                          key: const Key('device-songs-search-glass'),
                          quality: GlassQuality.blurred,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: TextField(
                            onChanged: (v) => setState(
                              () => _query = v.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: hasDrill
                                  ? l10n.deviceSongsSearchInList
                                  : l10n.deviceSongsSearchHint,
                              hintStyle: TextStyle(color: t.textMuted),
                              prefixIcon:
                                  Icon(Icons.search, color: t.textMuted),
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: t.textPrimary),
                          ),
                        ),
                      ),
                    ),
                    if (scanState.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: GlassSurface.card(
                            key: const Key('device-songs-scan-error-glass'),
                            quality: GlassQuality.frosted,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: t.textPrimary,
                                  size: 20,
                                  semanticLabel: l10n.commonError,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    l10n.deviceSongsScanFailed,
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref
                                      .read(
                                          deviceScanControllerProvider.notifier)
                                      .scan(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: t.textPrimary,
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: Text(l10n.commonTryAgain),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Drill header Play/Acak
                    if (hasDrill)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: deviceAsync.when(
                            data: (tracks) {
                              final List<Track> groupTracks;
                              if (isAlbumDetail) {
                                groupTracks = _sortedAlbumTracks(
                                  _groupByAlbum(
                                          tracks, l10n)[_selectedAlbumKey] ??
                                      [],
                                );
                              } else {
                                groupTracks = tracks
                                    .where((t) => t.artist == _selectedArtist)
                                    .toList();
                              }
                              final filtered = _filterSongs(groupTracks);
                              if (filtered.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final playQueue = isAlbumDetail
                                  ? _sortedAlbumTracks(filtered)
                                  : filtered;
                              return Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  ElevatedButton.icon(
                                    icon:
                                        const Icon(Icons.play_arrow, size: 20),
                                    label: Text(
                                      '${l10n.commonPlay} '
                                      '${l10n.commonSongCount(playQueue.length)}',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: t.accent,
                                      foregroundColor: t.onAccent,
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                    ),
                                    onPressed: () => ref
                                        .read(playerControllerProvider.notifier)
                                        .playTrack(
                                          playQueue.first,
                                          queue: playQueue,
                                        ),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.shuffle, size: 18),
                                    label: Text(l10n.commonShuffle),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: t.textPrimary,
                                      side: BorderSide(color: t.border),
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                    ),
                                    onPressed: () {
                                      final shuffled = List<Track>.of(playQueue)
                                        ..shuffle();
                                      ref
                                          .read(
                                              playerControllerProvider.notifier)
                                          .playTrack(
                                            shuffled.first,
                                            queue: shuffled,
                                          );
                                    },
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    // Filter chips — token fill, no blur
                    if (!hasDrill)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4,
                          ),
                          child: deviceAsync.when(
                            data: (tracks) {
                              if (tracks.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final artists = _groupByArtist(tracks, l10n);
                              final albums = _groupByAlbum(tracks, l10n);
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _GlassFilterChip(
                                      label: '${l10n.searchFilterSongs} • '
                                          '${tracks.length}',
                                      selected: _filter == DeviceFilter.songs,
                                      onSelected: () => setState(
                                        () => _filter = DeviceFilter.songs,
                                      ),
                                    ),
                                    _GlassFilterChip(
                                      label: '${l10n.searchFilterArtists} • '
                                          '${artists.length}',
                                      selected: _filter == DeviceFilter.artists,
                                      onSelected: () => setState(
                                        () => _filter = DeviceFilter.artists,
                                      ),
                                    ),
                                    _GlassFilterChip(
                                      label: '${l10n.searchFilterAlbums} • '
                                          '${albums.length}',
                                      selected: _filter == DeviceFilter.albums,
                                      onSelected: () => setState(
                                        () => _filter = DeviceFilter.albums,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    // Play All / Acak for songs tab
                    if (!hasDrill && _filter == DeviceFilter.songs)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: deviceAsync.when(
                            data: (tracks) {
                              if (tracks.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final filtered = _filterSongs(tracks);
                              if (filtered.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  ElevatedButton.icon(
                                    icon:
                                        const Icon(Icons.play_arrow, size: 20),
                                    label: Text(l10n.commonPlayAll),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: t.accent,
                                      foregroundColor: t.onAccent,
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                    ),
                                    onPressed: () => ref
                                        .read(playerControllerProvider.notifier)
                                        .playTrack(
                                          filtered.first,
                                          queue: filtered,
                                        ),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.shuffle, size: 18),
                                    label: Text(l10n.commonShuffle),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: t.textPrimary,
                                      side: BorderSide(color: t.border),
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                    ),
                                    onPressed: () {
                                      final shuffled = List<Track>.of(filtered)
                                        ..shuffle();
                                      ref
                                          .read(
                                              playerControllerProvider.notifier)
                                          .playTrack(
                                            shuffled.first,
                                            queue: shuffled,
                                          );
                                    },
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xs),
                    ),
                    SliverToBoxAdapter(
                      child: Divider(height: 1, color: t.border),
                    ),
                    // Content sliver
                    deviceAsync.when(
                      data: (tracks) => _buildContentSliver(
                        tracks,
                        scanState,
                        playerState,
                        isArtistAlbums,
                        isAlbumDetail,
                        theme,
                        t,
                        l10n,
                      ),
                      loading: () => const SliverToBoxAdapter(
                        child: ShimmerSection(itemCount: 6),
                      ),
                      error: (e, st) => SliverToBoxAdapter(
                        child: AppErrorState(
                          error: l10n.deviceSongsLoadError,
                          cause: e,
                          onRetry: () => ref.invalidate(deviceSongsProvider),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 160)),
                  ],
                ),
              ),
      ),
    );
  }

  /// Frosted glass row: the v3 material without a backdrop filter, so a long
  /// list never adds a blur layer (§0.7).
  Widget _glassRow({Key? key, required Widget child}) {
    return GlassSurface.card(
      key: key,
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  Widget _buildContentSliver(
    List<Track> tracks,
    DeviceScanState scanState,
    dynamic playerState,
    bool isArtistAlbums,
    bool isAlbumDetail,
    ThemeData theme,
    AppColorTokens t,
    AppLocalizations l10n,
  ) {
    if (tracks.isEmpty) {
      final scannedEmpty = scanState.scanCompleted;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: AppEmptyState(
            compact: true,
            icon:
                scannedEmpty ? Icons.search_off : Icons.folder_special_outlined,
            title: scannedEmpty
                ? l10n.deviceSongsEmptyScannedTitle
                : l10n.deviceSongsEmptyTitle,
            subtitle: scannedEmpty
                ? l10n.deviceSongsEmptyScannedSubtitle
                : l10n.deviceSongsEmptySubtitle,
            actionLabel: scannedEmpty
                ? l10n.librarySearchMusic
                : l10n.deviceSongsScanNow,
            onAction: scannedEmpty
                ? () => context.go('/search')
                : () => ref.read(deviceScanControllerProvider.notifier).scan(),
            secondaryLabel:
                scannedEmpty ? l10n.deviceSongsRescan : l10n.librarySearchMusic,
            onSecondaryAction: scannedEmpty
                ? () => ref.read(deviceScanControllerProvider.notifier).scan()
                : () => context.go('/search'),
          ),
        ),
      );
    }
    if (isArtistAlbums) {
      final map = _groupByAlbum(tracks, l10n);
      var entries = map.entries
          .where((e) => e.key.split('|||').last == _selectedArtist)
          .toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries = entries
            .where((e) => e.key.split('|||').first.toLowerCase().contains(q))
            .toList();
      }
      entries.sort((a, b) {
        final ya = a.value.first.year ?? 0;
        final yb = b.value.first.year ?? 0;
        if (ya != 0 && yb != 0 && ya != yb) return ya.compareTo(yb);
        return a.key.split('|||').first.toLowerCase().compareTo(
              b.key.split('|||').first.toLowerCase(),
            );
      });
      if (entries.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: AppEmptyState(
              icon: Icons.search_off,
              title: l10n.deviceSongsNoAlbums,
              subtitle: l10n.commonTryDifferentKeywords,
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: 4,
        ),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final album = e.key.split('|||').first;
            final list = _sortedAlbumTracks(e.value);
            final thumb = list
                .firstWhere(
                  (t) => t.localThumbnailPath != null,
                  orElse: () => list.first,
                )
                .localThumbnailPath;
            final isPlayingAlbum = list.any(
              (t) => t.sourceId == playerState.currentTrack?.sourceId,
            );
            final totalMs = list.fold<int>(0, (s, t) => s + t.durationMs);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _glassRow(
                key: ValueKey('device-album-glass-$album'),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  tileColor: isPlayingAlbum ? t.well : null,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: thumb != null
                        ? Image.file(
                            File(thumb),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: t.raised,
                              child: Icon(Icons.album, color: t.textMuted),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: t.raised,
                            child: Icon(Icons.album, color: t.textMuted),
                          ),
                  ),
                  title: Text(
                    album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPlayingAlbum ? t.accent : t.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${l10n.commonSongCount(list.length)} • '
                    '${_formatTotalDuration(totalMs, l10n)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: t.textSecondary),
                  ),
                  trailing: ExcludeSemantics(
                    child: Icon(Icons.chevron_right, color: t.textInactive),
                  ),
                  onTap: () => setState(() => _selectedAlbumKey = e.key),
                ),
              ),
            );
          },
        ),
      );
    }
    if (isAlbumDetail) {
      final rawList = _groupByAlbum(tracks, l10n)[_selectedAlbumKey] ?? [];
      final sorted = _sortedAlbumTracks(rawList);
      final filtered = _filterSongs(sorted);
      if (filtered.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: AppEmptyState(
              icon: Icons.search_off,
              title: l10n.searchNoResultsTitle,
              subtitle: l10n.commonTryDifferentKeywords,
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: 4,
        ),
        sliver: SliverList.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final track = filtered[index];
            final isPlaying =
                track.sourceId == playerState.currentTrack?.sourceId;
            final bitrateLabel =
                _formatBitrate(track.bitrateKbps, track.audioFormat);
            final subtitleParts = <String>[
              track.artist,
              _formatDuration(track.durationMs),
              if (bitrateLabel.isNotEmpty) bitrateLabel,
            ];
            final trackNo = track.trackNumber;
            return _glassRow(
              key: ValueKey('device-song-glass-${track.sourceId}'),
              child: AppTrackTile(
                title: track.title,
                subtitle: subtitleParts.join(' • '),
                localThumbnailPath: track.localThumbnailPath,
                isPlaying: isPlaying,
                isCached: true,
                leadingCustom: trackNo != null
                    ? Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? t.accent.withValues(alpha: 0.15)
                              : t.raised,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '$trackNo',
                          style: TextStyle(
                            color: isPlaying ? t.accent : t.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
                trailing: isPlaying
                    ? Icon(
                        Icons.equalizer,
                        color: t.accent,
                        semanticLabel: l10n.browseNowPlaying,
                      )
                    : AppIconButton(
                        icon: Icons.more_vert,
                        semanticLabel: l10n.commonTrackOptions,
                        iconSize: 20,
                        filled: false,
                        onPressed: () =>
                            _showOptions(context, ref, track, filtered),
                      ),
                onTap: () => ref
                    .read(playerControllerProvider.notifier)
                    .playTrack(track, queue: filtered),
              ),
            );
          },
        ),
      );
    }
    if (_filter == DeviceFilter.artists) {
      final map = _groupByArtist(tracks, l10n);
      var entries = map.entries.toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries =
            entries.where((e) => e.key.toLowerCase().contains(q)).toList();
      }
      entries.sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );
      if (entries.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: AppEmptyState(
              icon: Icons.search_off,
              title: l10n.deviceSongsNoArtists,
              subtitle: l10n.commonTryDifferentKeywords,
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: 4,
        ),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final artist = e.key;
            final list = e.value;
            final totalMs = list.fold<int>(0, (s, t) => s + t.durationMs);
            final thumb = list
                .firstWhere(
                  (t) => t.localThumbnailPath != null,
                  orElse: () => list.first,
                )
                .localThumbnailPath;
            final isPlayingArtist = list.any(
              (t) => t.sourceId == playerState.currentTrack?.sourceId,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _glassRow(
                key: ValueKey('device-artist-glass-$artist'),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  tileColor: isPlayingArtist ? t.well : null,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: thumb != null
                        ? Image.file(
                            File(thumb),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: t.raised,
                              child: Icon(Icons.person, color: t.textMuted),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: t.raised,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Icon(Icons.person, color: t.textMuted),
                          ),
                  ),
                  title: Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPlayingArtist ? t.accent : t.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${l10n.commonSongCount(list.length)} • '
                    '${_formatTotalDuration(totalMs, l10n)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: t.textSecondary),
                  ),
                  trailing: ExcludeSemantics(
                    child: Icon(Icons.chevron_right, color: t.textInactive),
                  ),
                  onTap: () => setState(() => _selectedArtist = artist),
                ),
              ),
            );
          },
        ),
      );
    }
    if (_filter == DeviceFilter.albums) {
      final map = _groupByAlbum(tracks, l10n);
      var entries = map.entries.toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries = entries.where((e) {
          final album = e.key.split('|||').first.toLowerCase();
          final artist = e.key.split('|||').last.toLowerCase();
          return album.contains(q) || artist.contains(q);
        }).toList();
      }
      entries.sort(
        (a, b) => a.key
            .split('|||')
            .first
            .toLowerCase()
            .compareTo(b.key.split('|||').first.toLowerCase()),
      );
      if (entries.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: AppEmptyState(
              icon: Icons.search_off,
              title: l10n.deviceSongsNoAlbums,
              subtitle: l10n.commonTryDifferentKeywords,
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: 4,
        ),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final album = e.key.split('|||').first;
            final artist = e.key.split('|||').length > 1
                ? e.key.split('|||')[1]
                : l10n.browseUnknownArtist;
            final list = e.value;
            final thumb = list
                .firstWhere(
                  (t) => t.localThumbnailPath != null,
                  orElse: () => list.first,
                )
                .localThumbnailPath;
            final isPlayingAlbum = list.any(
              (t) => t.sourceId == playerState.currentTrack?.sourceId,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _glassRow(
                key: ValueKey('device-album-glass-$album'),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  tileColor: isPlayingAlbum ? t.well : null,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: thumb != null
                        ? Image.file(
                            File(thumb),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: t.raised,
                              child: Icon(Icons.album, color: t.textMuted),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: t.raised,
                            child: Icon(Icons.album, color: t.textMuted),
                          ),
                  ),
                  title: Text(
                    album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPlayingAlbum ? t.accent : t.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '$artist • ${l10n.commonSongCount(list.length)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: t.textSecondary),
                  ),
                  trailing: ExcludeSemantics(
                    child: Icon(Icons.chevron_right, color: t.textInactive),
                  ),
                  onTap: () => setState(() => _selectedAlbumKey = e.key),
                ),
              ),
            );
          },
        ),
      );
    }
    final filtered = _filterSongs(tracks);
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: AppEmptyState(
            icon: Icons.search_off,
            title: l10n.searchNoResultsTitle,
            subtitle: l10n.commonTryDifferentKeywords,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: 4,
      ),
      sliver: SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final track = filtered[index];
          final isPlaying =
              track.sourceId == playerState.currentTrack?.sourceId;
          final bitrateLabel =
              _formatBitrate(track.bitrateKbps, track.audioFormat);
          final subtitleParts = <String>[
            track.artist,
            if (track.album != null) track.album!,
            _formatDuration(track.durationMs),
            if (bitrateLabel.isNotEmpty) bitrateLabel,
            _fmtSize(track.fileSizeBytes),
          ];
          return _glassRow(
            key: ValueKey('device-song-glass-${track.sourceId}'),
            child: AppTrackTile(
              title: track.title,
              subtitle: subtitleParts.join(' • '),
              localThumbnailPath: track.localThumbnailPath,
              isPlaying: isPlaying,
              isCached: true,
              trailing: isPlaying
                  ? Icon(
                      Icons.equalizer,
                      color: t.accent,
                      semanticLabel: l10n.browseNowPlaying,
                    )
                  : AppIconButton(
                      icon: Icons.more_vert,
                      semanticLabel: l10n.commonTrackOptions,
                      iconSize: 20,
                      filled: false,
                      onPressed: () =>
                          _showOptions(context, ref, track, filtered),
                    ),
              onTap: () => ref
                  .read(playerControllerProvider.notifier)
                  .playTrack(track, queue: filtered),
            ),
          );
        },
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Track> queue,
  ) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final tt = AppColors.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tt.raised,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Icon(Icons.play_arrow, color: tt.textPrimary),
                  title: Text(
                    l10n.commonPlay,
                    style: TextStyle(color: tt.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(playerControllerProvider.notifier)
                        .playTrack(track, queue: queue);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.queue_music, color: tt.textPrimary),
                  title: Text(
                    l10n.deviceSongsAddToQueue,
                    style: TextStyle(color: tt.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(playerControllerProvider.notifier)
                        .addToQueue(track);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.deviceSongsAddedToQueue)),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.skip_next, color: tt.textPrimary),
                  title: Text(
                    l10n.deviceSongsPlayNext,
                    style: TextStyle(color: tt.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(playerControllerProvider.notifier)
                        .addToQueue(track, playNext: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.deviceSongsWillPlayNext),
                      ),
                    );
                  },
                ),
                if (track.bitrateKbps != null ||
                    track.audioFormat != null ||
                    track.fileSizeBytes != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tt.raised,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.high_quality,
                            size: 14,
                            color: tt.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              [
                                if (track.audioFormat != null)
                                  track.audioFormat!.toUpperCase(),
                                if (track.bitrateKbps != null)
                                  '${track.bitrateKbps} kbps',
                                if (track.fileSizeBytes != null)
                                  _fmtSize(track.fileSizeBytes),
                                _formatDuration(track.durationMs),
                              ].join(' • '),
                              style: TextStyle(
                                color: tt.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.folder_open, color: tt.textMuted),
                  title: Text(
                    track.localAudioPath ?? '',
                    style: TextStyle(color: tt.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Device filter chip on the v3 chip tokens. Chips never blur (§0.2).
class _GlassFilterChip extends StatelessWidget {
  const _GlassFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final glass = AppGlass.of(context);
    final t = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: glass.chipSubtleFill,
        selectedColor: glass.chipSelectedFill,
        labelStyle: TextStyle(
          color: selected ? t.textPrimary : t.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? glass.chipSelectedBorder : glass.chipSubtleBorder,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
