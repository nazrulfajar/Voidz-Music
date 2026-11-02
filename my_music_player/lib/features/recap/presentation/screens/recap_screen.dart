import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/recap.dart';
import '../../domain/entities/recap_period.dart';
import '../providers/recap_provider.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedRecapPeriodProvider);
    final year = ref.watch(selectedRecapYearProvider);
    final month = ref.watch(selectedRecapMonthProvider);
    final label = _recapPeriodLabel(period, year, month);
    final periodPhrase = _recapPeriodPhrase(period, year, month);
    final query = (
      year: year,
      month: period == RecapPeriod.month ? month : null,
    );
    final recapAsync = ref.watch(recapProvider(query));
    final yearsAsync = ref.watch(recapYearsProvider);
    final years = <int>{
      year,
      ...?yearsAsync.valueOrNull,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        title: const Text(
          'Rekap',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _PeriodControls(
            period: period,
            year: year,
            month: month,
            label: label,
            years: years,
            onPeriodChanged: (value) =>
                ref.read(selectedRecapPeriodProvider.notifier).state = value,
            onMonthChanged: (value) =>
                ref.read(selectedRecapMonthProvider.notifier).state = value,
            onYearChanged: (value) =>
                ref.read(selectedRecapYearProvider.notifier).state = value,
          ),
          Expanded(
            child: recapAsync.when(
              data: (recap) {
                if (recap.totalPlays == 0) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Belum ada rekap $label',
                      subtitle:
                          'Putar lagu dulu, rekap akan muncul di sini.\nHistory max 10000 play.',
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.accentPrimary,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: () async => ref.invalidate(recapProvider(query)),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _HeaderStats(recap: recap)),
                      SliverToBoxAdapter(
                        child: _MostPlayedCard(
                          track: recap.mostPlayed!,
                          count: recap.mostPlayedCount,
                          periodLabel: label,
                          ref: ref,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Top 5 Lagu',
                          subtitle: 'Paling sering diputar $periodPhrase',
                        ),
                      ),
                      SliverList.builder(
                        itemCount: recap.topSongs.length,
                        itemBuilder: (c, i) => _SongTile(
                          rank: i + 1,
                          track: recap.topSongs[i],
                          count: recap.topSongCounts[i],
                          ref: ref,
                          queue: recap.topSongs,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Top 5 Artis',
                          subtitle: 'Artis teratasmu',
                        ),
                      ),
                      SliverList.builder(
                        itemCount: recap.topArtists.length,
                        itemBuilder: (c, i) => _ArtistTile(
                          rank: i + 1,
                          data: recap.topArtists[i],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Top 5 Album',
                          subtitle: 'Album paling diputar',
                        ),
                      ),
                      SliverList.builder(
                        itemCount: recap.topAlbums.length,
                        itemBuilder: (c, i) => _AlbumTile(
                          rank: i + 1,
                          data: recap.topAlbums[i],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const ShimmerSection(isGrid: false, itemCount: 6),
              error: (e, st) => Center(
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat rekap',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _recapPeriodLabel(RecapPeriod period, int year, int month) {
  if (period == RecapPeriod.year) return '$year';
  return '${_monthNames[month - 1]} $year';
}

String _recapPeriodPhrase(RecapPeriod period, int year, int month) {
  if (period == RecapPeriod.year) return 'tahun $year';
  return _recapPeriodLabel(period, year, month);
}

class _PeriodControls extends StatelessWidget {
  const _PeriodControls({
    required this.period,
    required this.year,
    required this.month,
    required this.label,
    required this.years,
    required this.onPeriodChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final RecapPeriod period;
  final int year;
  final int month;
  final String label;
  final List<int> years;
  final ValueChanged<RecapPeriod> onPeriodChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppFilterChip(
                label: 'Bulan',
                selected: period == RecapPeriod.month,
                onSelected: () => onPeriodChanged(RecapPeriod.month),
              ),
              AppFilterChip(
                label: 'Tahun',
                selected: period == RecapPeriod.year,
                onSelected: () => onPeriodChanged(RecapPeriod.year),
              ),
              if (period == RecapPeriod.month)
                _MonthDropdown(value: month, onChanged: onMonthChanged),
              _YearDropdown(
                  value: year, years: years, onChanged: onYearChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButton<int>(
      value: value,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox.shrink(),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
      items: [
        for (var month = 1; month <= 12; month++)
          DropdownMenuItem(
            value: month,
            child: Text(_monthNames[month - 1]),
          ),
      ],
      onChanged: (month) {
        if (month != null) onChanged(month);
      },
    );
  }
}

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.value,
    required this.years,
    required this.onChanged,
  });

  final int value;
  final List<int> years;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButton<int>(
      value: value,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox.shrink(),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
      items: [
        for (final year in years)
          DropdownMenuItem(value: year, child: Text('$year')),
      ],
      onChanged: (year) {
        if (year != null) onChanged(year);
      },
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final Recap recap;
  const _HeaderStats({required this.recap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Putar', value: '${recap.totalPlays}'),
          Container(width: 1, height: 40, color: AppColors.surfaceOverlay),
          _StatItem(label: 'Lagu Unik', value: '${recap.totalTracks}'),
          Container(width: 1, height: 40, color: AppColors.surfaceOverlay),
          _StatItem(label: 'Tahun', value: '${recap.year}'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accentPrimary, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
    ]);
  }
}

class _MostPlayedCard extends StatelessWidget {
  final Track track;
  final int count;
  final String periodLabel;
  final WidgetRef ref;
  const _MostPlayedCard({required this.track, required this.count, required this.periodLabel, required this.ref});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accentPrimary.withValues(alpha: 0.9), Colors.purpleAccent.withValues(alpha: 0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => ref.read(playerControllerProvider.notifier).playTrack(track, queue: [track]),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('#1 MOST PLAYED $periodLabel', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1))),
                  const Spacer(),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: track.localThumbnailPath != null && File(track.localThumbnailPath!).existsSync()
                          ? Image.file(File(track.localThumbnailPath!), width: 96, height: 96, fit: BoxFit.cover)
                          : track.thumbnailUrl != null
                              ? CachedNetworkImage(imageUrl: track.thumbnailUrl!, width: 96, height: 96, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fallback96())
                              : _fallback96(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        if (track.album != null) Text(track.album!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('$count× diputar', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback96() => Container(width: 96, height: 96, color: Colors.white24, child: const Icon(Icons.music_note, color: Colors.white, size: 48));
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _SongTile extends StatelessWidget {
  final int rank;
  final Track track;
  final int count;
  final WidgetRef ref;
  final List<Track> queue;
  const _SongTile({required this.rank, required this.track, required this.count, required this.ref, required this.queue});
  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerTrack = ref.watch(playerControllerProvider).currentTrack;
    final isPlaying = playerTrack?.sourceId == track.sourceId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: isPlaying ? AppColors.surfaceHover : AppColors.surfaceElevated.withValues(alpha: 0.4),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: track.localThumbnailPath != null && File(track.localThumbnailPath!).existsSync()
                  ? Image.file(File(track.localThumbnailPath!), width: 56, height: 56, fit: BoxFit.cover)
                  : track.thumbnailUrl != null
                      ? CachedNetworkImage(imageUrl: track.thumbnailUrl!, width: 56, height: 56, fit: BoxFit.cover, errorWidget: (_, __, ___) => _thumbFallback())
                      : _thumbFallback(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: rank == 1 ? AppColors.accentPrimary : Colors.black87, borderRadius: BorderRadius.circular(6)),
              child: Text('#$rank', style: TextStyle(color: rank == 1 ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: isPlaying ? AppColors.accentPrimary : AppColors.textPrimary)),
        subtitle: Text('${track.artist} • ${_fmt(track.durationMs)} • $count×', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        trailing: isPlaying ? const Icon(Icons.equalizer, color: AppColors.accentPrimary) : Text('$count', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
        onTap: () => ref.read(playerControllerProvider.notifier).playTrack(track, queue: queue),
      ),
    );
  }

  Widget _thumbFallback() => Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary));
}

class _ArtistTile extends StatelessWidget {
  final int rank;
  final ArtistCount data;
  const _ArtistTile({required this.rank, required this.data});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: AppColors.surfaceElevated.withValues(alpha: 0.4),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceOverlay,
                shape: BoxShape.circle,
                image: data.thumbLocal != null && File(data.thumbLocal!).existsSync()
                    ? DecorationImage(image: FileImage(File(data.thumbLocal!)), fit: BoxFit.cover)
                    : data.thumb != null
                        ? DecorationImage(image: CachedNetworkImageProvider(data.thumb!), fit: BoxFit.cover)
                        : null,
              ),
              child: (data.thumbLocal == null || !File(data.thumbLocal!).existsSync()) && data.thumb == null ? const Icon(Icons.person, color: AppColors.textTertiary) : null,
            ),
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.surfaceBase, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceOverlay)), child: Text('$rank', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        ),
        title: Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text('${data.count}× diputar', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.accentPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('#$rank', style: const TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final int rank;
  final AlbumCount data;
  const _AlbumTile({required this.rank, required this.data});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: AppColors.surfaceElevated.withValues(alpha: 0.4),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: data.thumbLocal != null && File(data.thumbLocal!).existsSync()
                  ? Image.file(File(data.thumbLocal!), width: 56, height: 56, fit: BoxFit.cover)
                  : data.thumb != null
                      ? CachedNetworkImage(imageUrl: data.thumb!, width: 56, height: 56, fit: BoxFit.cover, errorWidget: (_, __, ___) => _thumbFallback())
                      : _thumbFallback(),
            ),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)), child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        ),
        title: Text(data.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text('${data.artist} • ${data.count}×', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.album, color: AppColors.textTertiary, size: 20),
      ),
    );
  }

  Widget _thumbFallback() => Container(width: 56, height: 56, color: AppColors.surfaceOverlay, child: const Icon(Icons.album, color: AppColors.textTertiary));
}
