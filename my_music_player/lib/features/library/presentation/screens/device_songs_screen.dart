import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../player/domain/entities/track.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_list_tile.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
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

  String _formatTotalDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
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

  Map<String, List<Track>> _groupByArtist(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final key = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Map<String, List<Track>> _groupByAlbum(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final album = (t.album == null || t.album!.trim().isEmpty) ? 'Unknown Album' : t.album!.trim();
      final artist = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
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
        backgroundColor: AppColors.surfaceBase,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBase,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: hasDrill
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => setState(() {
                    if (_selectedAlbumKey != null) {
                      _selectedAlbumKey = null;
                    } else {
                      _selectedArtist = null;
                    }
                  }),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAlbumDetail ? _selectedAlbumKey!.split('|||').first : (_selectedArtist ?? 'Di Perangkat'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              deviceAsync.when(
                data: (tracks) {
                  if (isAlbumDetail) {
                    final list = _groupByAlbum(tracks)[_selectedAlbumKey] ?? [];
                    if (list.isEmpty) return const SizedBox.shrink();
                    final totalMs = list.fold<int>(0, (s, t) => s + t.durationMs);
                    return Text('${list.length} lagu • ${_formatTotalDuration(totalMs)} • ${list.first.artist}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis);
                  }
                  if (isArtistAlbums) {
                    final albumCount = _groupByAlbum(tracks).keys.where((k) => k.split('|||').last == _selectedArtist).length;
                    final songCount = tracks.where((t) => t.artist == _selectedArtist).length;
                    return Text('$albumCount album • $songCount lagu', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary));
                  }
                  int bytes = 0;
                  for (final t in tracks) bytes += t.fileSizeBytes ?? 0;
                  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
                  return Text('${tracks.length} lagu • $mb MB', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary));
                },
                loading: () => Text('Memuat...', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            if (scanState.isScanning)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary)),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                onPressed: () => ref.read(deviceScanControllerProvider.notifier).scan(),
                tooltip: 'Pindai ulang',
              ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () async => await ref.read(deviceScanControllerProvider.notifier).scan(),
          child: CustomScrollView(
            slivers: [
              // Search — opaque sticky
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surfaceBase,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: hasDrill ? 'Cari di daftar ini' : 'Cari lagu, artis, album',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              // Permission banner
              if (scanState.permissionDenied)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [const Icon(Icons.folder_off, color: AppColors.statusWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('Izin akses musik diperlukan', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)))]),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Agar dapat menampilkan lagu di penyimpanan, izinkan akses media audio.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.md),
                          Row(children: [Expanded(child: ElevatedButton(onPressed: () async { if (scanState.permanentlyDenied) { await openAppSettings(); } else { await ref.read(deviceScanControllerProvider.notifier).scan(); } }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black), child: Text(scanState.permanentlyDenied ? 'Buka Pengaturan' : 'Izinkan'))), const SizedBox(width: AppSpacing.sm), TextButton(onPressed: () => ref.read(deviceScanControllerProvider.notifier).checkPermissionStatus(), child: const Text('Cek lagi', style: TextStyle(color: AppColors.textSecondary)))]),
                        ],
                      ),
                    ),
                  ),
                ),
              if (scanState.error != null)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(color: AppColors.statusError.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [const Icon(Icons.error_outline, color: AppColors.statusError, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(scanState.error!, style: const TextStyle(color: AppColors.statusError, fontSize: 13))), IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.statusError), onPressed: () => ref.read(deviceScanControllerProvider.notifier).scan())]),
                    ),
                  ),
                ),
              // Drill header Play/Acak
              if (hasDrill)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: deviceAsync.when(
                      data: (tracks) {
                        final List<Track> groupTracks;
                        if (isAlbumDetail) {
                          groupTracks = _sortedAlbumTracks(_groupByAlbum(tracks)[_selectedAlbumKey] ?? []);
                        } else {
                          groupTracks = tracks.where((t) => t.artist == _selectedArtist).toList();
                        }
                        final filtered = _filterSongs(groupTracks);
                        if (filtered.isEmpty) return const SizedBox.shrink();
                        final playQueue = isAlbumDetail ? _sortedAlbumTracks(filtered) : filtered;
                        return Row(children: [Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.play_arrow, size: 20), label: Text('Putar ${playQueue.length} lagu'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))), onPressed: () => ref.read(playerControllerProvider.notifier).playTrack(playQueue.first, queue: playQueue))), const SizedBox(width: AppSpacing.sm), OutlinedButton.icon(icon: const Icon(Icons.shuffle, size: 18), label: const Text('Acak'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.surfaceOverlay), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))), onPressed: () { final shuffled = List<Track>.of(playQueue)..shuffle(); ref.read(playerControllerProvider.notifier).playTrack(shuffled.first, queue: shuffled); })]);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // Filter chips
              if (!hasDrill)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    child: deviceAsync.when(
                      data: (tracks) {
                        if (tracks.isEmpty) return const SizedBox.shrink();
                        final artists = _groupByArtist(tracks);
                        final albums = _groupByAlbum(tracks);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [AppFilterChip(label: 'Lagu • ${tracks.length}', selected: _filter == DeviceFilter.songs, onSelected: () => setState(() => _filter = DeviceFilter.songs)), AppFilterChip(label: 'Artis • ${artists.length}', selected: _filter == DeviceFilter.artists, onSelected: () => setState(() => _filter = DeviceFilter.artists)), AppFilterChip(label: 'Album • ${albums.length}', selected: _filter == DeviceFilter.albums, onSelected: () => setState(() => _filter = DeviceFilter.albums))]),
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
                  child: Container(
                    color: AppColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: deviceAsync.when(
                      data: (tracks) {
                        if (tracks.isEmpty) return const SizedBox.shrink();
                        final filtered = _filterSongs(tracks);
                        if (filtered.isEmpty) return const SizedBox.shrink();
                        return Row(children: [Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.play_arrow, size: 20), label: const Text('Putar Semua'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))), onPressed: () => ref.read(playerControllerProvider.notifier).playTrack(filtered.first, queue: filtered))), const SizedBox(width: AppSpacing.sm), Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.shuffle, size: 18), label: const Text('Acak'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.surfaceOverlay), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))), onPressed: () { final shuffled = List<Track>.of(filtered)..shuffle(); ref.read(playerControllerProvider.notifier).playTrack(shuffled.first, queue: shuffled); }))]);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: Container(color: AppColors.surfaceBase, height: AppSpacing.xs)),
              SliverToBoxAdapter(child: Container(color: AppColors.surfaceBase, child: const Divider(height: 1, color: AppColors.surfaceOverlay))),
              // Content sliver
              deviceAsync.when(
                data: (tracks) => _buildContentSliver(tracks, playerState, isArtistAlbums, isAlbumDetail, theme),
                loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)))),
                error: (e, st) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e', style: const TextStyle(color: AppColors.statusError)))),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver(List<Track> tracks, dynamic playerState, bool isArtistAlbums, bool isAlbumDetail, ThemeData theme) {
    if (tracks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: AppEmptyState(
            icon: Icons.folder_special_outlined,
            title: 'Tidak ada lagu di perangkat',
            subtitle: 'Letakkan file MP3/M4A/FLAC di folder Music atau Download, lalu tarik untuk pindai',
            action: ElevatedButton.icon(onPressed: () => ref.read(deviceScanControllerProvider.notifier).scan(), icon: const Icon(Icons.refresh), label: const Text('Pindai Sekarang'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black)),
          ),
        ),
      );
    }
    if (isArtistAlbums) {
      final map = _groupByAlbum(tracks);
      var entries = map.entries.where((e) => e.key.split('|||').last == _selectedArtist).toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries = entries.where((e) => e.key.split('|||').first.toLowerCase().contains(q)).toList();
      }
      entries.sort((a, b) {
        final ya = a.value.first.year ?? 0;
        final yb = b.value.first.year ?? 0;
        if (ya != 0 && yb != 0 && ya != yb) return ya.compareTo(yb);
        return a.key.split('|||').first.toLowerCase().compareTo(b.key.split('|||').first.toLowerCase());
      });
      if (entries.isEmpty) {
        return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: AppEmptyState(icon: Icons.search_off, title: 'Tidak ada album', subtitle: 'Coba kata kunci lain')));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: 4),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final album = e.key.split('|||').first;
            final list = _sortedAlbumTracks(e.value);
            final thumb = list.firstWhere((t) => t.localThumbnailPath != null, orElse: () => list.first).localThumbnailPath;
            final isPlayingAlbum = list.any((t) => t.sourceId == playerState.currentTrack?.sourceId);
            final totalMs = list.fold<int>(0, (s, t) => s + t.durationMs);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                tileColor: isPlayingAlbum ? AppColors.surfaceHover : null,
                leading: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: thumb != null ? Image.file(File(thumb), width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 120, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.album, color: AppColors.textTertiary))) : Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.album, color: AppColors.textTertiary))),
                title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: isPlayingAlbum ? AppColors.accentPrimary : AppColors.textPrimary)),
                subtitle: Text('${list.length} lagu • ${_formatTotalDuration(totalMs)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                onTap: () => setState(() => _selectedAlbumKey = e.key),
              ),
            );
          },
        ),
      );
    }
    if (isAlbumDetail) {
      final rawList = _groupByAlbum(tracks)[_selectedAlbumKey] ?? [];
      final sorted = _sortedAlbumTracks(rawList);
      final filtered = _filterSongs(sorted);
      if (filtered.isEmpty) {
        return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: AppEmptyState(icon: Icons.search_off, title: 'Tidak ada hasil', subtitle: 'Coba kata kunci lain')));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm, top: 4),
        sliver: SliverList.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final track = filtered[index];
            final isPlaying = track.sourceId == playerState.currentTrack?.sourceId;
            final bitrateLabel = _formatBitrate(track.bitrateKbps, track.audioFormat);
            final subtitleParts = <String>[track.artist, _formatDuration(track.durationMs), if (bitrateLabel.isNotEmpty) bitrateLabel];
            final trackNo = track.trackNumber;
            return AppTrackTile(title: track.title, subtitle: subtitleParts.join(' • '), localThumbnailPath: track.localThumbnailPath, isPlaying: isPlaying, isCached: true, leadingCustom: trackNo != null ? Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: isPlaying ? AppColors.accentPrimary.withValues(alpha: 0.15) : AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Text('$trackNo', style: TextStyle(color: isPlaying ? AppColors.accentPrimary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14))) : null, trailing: isPlaying ? const Icon(Icons.equalizer, color: AppColors.accentPrimary) : IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textTertiary, size: 20), onPressed: () => _showOptions(context, ref, track, filtered)), onTap: () => ref.read(playerControllerProvider.notifier).playTrack(track, queue: filtered));
          },
        ),
      );
    }
    if (_filter == DeviceFilter.artists) {
      final map = _groupByArtist(tracks);
      var entries = map.entries.toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries = entries.where((e) => e.key.toLowerCase().contains(q)).toList();
      }
      entries.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      if (entries.isEmpty) {
        return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: AppEmptyState(icon: Icons.search_off, title: 'Tidak ada artis', subtitle: 'Coba kata kunci lain')));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: 4),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final artist = e.key;
            final list = e.value;
            final totalMs = list.fold<int>(0, (s, t) => s + t.durationMs);
            final thumb = list.firstWhere((t) => t.localThumbnailPath != null, orElse: () => list.first).localThumbnailPath;
            final isPlayingArtist = list.any((t) => t.sourceId == playerState.currentTrack?.sourceId);
            return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)), tileColor: isPlayingArtist ? AppColors.surfaceHover : null, leading: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.full), child: thumb != null ? Image.file(File(thumb), width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 120, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.person, color: AppColors.textTertiary))) : Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(AppRadius.full)), child: const Icon(Icons.person, color: AppColors.textTertiary))), title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: isPlayingArtist ? AppColors.accentPrimary : AppColors.textPrimary)), subtitle: Text('${list.length} lagu • ${_formatTotalDuration(totalMs)}', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)), trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary), onTap: () => setState(() => _selectedArtist = artist)));
          },
        ),
      );
    }
    if (_filter == DeviceFilter.albums) {
      final map = _groupByAlbum(tracks);
      var entries = map.entries.toList();
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        entries = entries.where((e) { final album = e.key.split('|||').first.toLowerCase(); final artist = e.key.split('|||').last.toLowerCase(); return album.contains(q) || artist.contains(q); }).toList();
      }
      entries.sort((a, b) => a.key.split('|||').first.toLowerCase().compareTo(b.key.split('|||').first.toLowerCase()));
      if (entries.isEmpty) {
        return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: AppEmptyState(icon: Icons.search_off, title: 'Tidak ada album', subtitle: 'Coba kata kunci lain')));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: 4),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, idx) {
            final e = entries[idx];
            final album = e.key.split('|||').first;
            final artist = e.key.split('|||').length > 1 ? e.key.split('|||')[1] : 'Unknown Artist';
            final list = e.value;
            final thumb = list.firstWhere((t) => t.localThumbnailPath != null, orElse: () => list.first).localThumbnailPath;
            final isPlayingAlbum = list.any((t) => t.sourceId == playerState.currentTrack?.sourceId);
            return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)), tileColor: isPlayingAlbum ? AppColors.surfaceHover : null, leading: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: thumb != null ? Image.file(File(thumb), width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 120, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.album, color: AppColors.textTertiary))) : Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.album, color: AppColors.textTertiary))), title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: isPlayingAlbum ? AppColors.accentPrimary : AppColors.textPrimary)), subtitle: Text('$artist • ${list.length} lagu', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)), trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary), onTap: () => setState(() => _selectedAlbumKey = e.key)));
          },
        ),
      );
    }
    final filtered = _filterSongs(tracks);
    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: AppEmptyState(icon: Icons.search_off, title: 'Tidak ada hasil', subtitle: 'Coba kata kunci lain')));
    }
    return SliverPadding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm, top: 4),
      sliver: SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final track = filtered[index];
          final isPlaying = track.sourceId == playerState.currentTrack?.sourceId;
          final bitrateLabel = _formatBitrate(track.bitrateKbps, track.audioFormat);
          final subtitleParts = <String>[track.artist, if (track.album != null) track.album!, _formatDuration(track.durationMs), if (bitrateLabel.isNotEmpty) bitrateLabel, _fmtSize(track.fileSizeBytes)];
          return AppTrackTile(title: track.title, subtitle: subtitleParts.join(' • '), localThumbnailPath: track.localThumbnailPath, isPlaying: isPlaying, isCached: true, trailing: isPlaying ? const Icon(Icons.equalizer, color: AppColors.accentPrimary) : IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textTertiary, size: 20), onPressed: () => _showOptions(context, ref, track, filtered)), onTap: () => ref.read(playerControllerProvider.notifier).playTrack(track, queue: filtered));
        },
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, Track track, List<Track> queue) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceElevated, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))), builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: AppSpacing.sm), Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(2))), const SizedBox(height: AppSpacing.md), ListTile(leading: const Icon(Icons.play_arrow, color: AppColors.textPrimary), title: const Text('Putar', style: TextStyle(color: AppColors.textPrimary)), onTap: () { Navigator.pop(ctx); ref.read(playerControllerProvider.notifier).playTrack(track, queue: queue); }), ListTile(leading: const Icon(Icons.queue_music, color: AppColors.textPrimary), title: const Text('Tambah ke antrean', style: TextStyle(color: AppColors.textPrimary)), onTap: () { Navigator.pop(ctx); ref.read(playerControllerProvider.notifier).addToQueue(track); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke antrean'))); }), ListTile(leading: const Icon(Icons.skip_next, color: AppColors.textPrimary), title: const Text('Putar berikutnya', style: TextStyle(color: AppColors.textPrimary)), onTap: () { Navigator.pop(ctx); ref.read(playerControllerProvider.notifier).addToQueue(track, playNext: true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akan diputar berikutnya'))); }), if (track.bitrateKbps != null || track.audioFormat != null || track.fileSizeBytes != null) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.high_quality, size: 14, color: AppColors.textTertiary), const SizedBox(width: 6), Text([if (track.audioFormat != null) track.audioFormat!.toUpperCase(), if (track.bitrateKbps != null) '${track.bitrateKbps} kbps', if (track.fileSizeBytes != null) _fmtSize(track.fileSizeBytes), _formatDuration(track.durationMs)].join(' • '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]))), ListTile(leading: const Icon(Icons.folder_open, color: AppColors.textTertiary), title: Text(track.localAudioPath ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)), const SizedBox(height: AppSpacing.md)])));
  }
}
