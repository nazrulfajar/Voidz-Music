import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/app_empty_state.dart';
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
    final tokens = AppColors.of(context);
    final period = ref.watch(selectedRecapPeriodProvider);
    final year = ref.watch(selectedRecapYearProvider);
    final month = ref.watch(selectedRecapMonthProvider).clamp(1, 12);
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
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        title: Text(
          'Rekap',
          style: TextStyle(
            color: tokens.textPrimary,
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
                  color: tokens.accent,
                  backgroundColor: tokens.raised,
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
              error: (e, st) => AppErrorState(
                error: 'Gagal memuat rekap. Periksa koneksi lalu coba lagi.',
                onRetry: () => ref.invalidate(recapProvider(query)),
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
  final safeMonth = month.clamp(1, 12);
  return '${_monthNames[safeMonth - 1]} $year';
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
    required this.years,
    required this.onPeriodChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final RecapPeriod period;
  final int year;
  final int month;
  final List<int> years;
  final ValueChanged<RecapPeriod> onPeriodChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
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
              ChoiceChip(
                label: const Text('Bulan'),
                selected: period == RecapPeriod.month,
                onSelected: (_) => onPeriodChanged(RecapPeriod.month),
              ),
              ChoiceChip(
                label: const Text('Tahun'),
                selected: period == RecapPeriod.year,
                onSelected: (_) => onPeriodChanged(RecapPeriod.year),
              ),
              if (period == RecapPeriod.month)
                _PeriodDropdown<int>(
                  value: month,
                  semanticLabel: 'Pilih bulan',
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(_monthNames[month - 1]),
                      ),
                  ],
                  onChanged: onMonthChanged,
                ),
              _PeriodDropdown<int>(
                value: year,
                semanticLabel: 'Pilih tahun',
                items: [
                  for (final year in years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: onYearChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _recapPeriodLabel(period, year, month),
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown<T> extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.semanticLabel,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Semantics(
      label: semanticLabel,
      child: DropdownButton<T>(
        value: value,
        dropdownColor: tokens.raised,
        underline: const SizedBox.shrink(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        icon: Icon(Icons.arrow_drop_down, color: tokens.textPrimary),
        items: items,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final Recap recap;
  const _HeaderStats({required this.recap});

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                _StatItem(label: 'Total Putar', value: '${recap.totalPlays}'),
          ),
          Container(width: 1, height: 40, color: tokens.border),
          Expanded(
            child: _StatItem(label: 'Lagu Unik', value: '${recap.totalTracks}'),
          ),
          Container(width: 1, height: 40, color: tokens.border),
          Expanded(
            child: _StatItem(label: 'Tahun', value: '${recap.year}'),
          ),
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
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: tokens.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MostPlayedCard extends StatelessWidget {
  final Track track;
  final int count;
  final String periodLabel;
  final WidgetRef ref;
  const _MostPlayedCard({
    required this.track,
    required this.count,
    required this.periodLabel,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final onGradient = tokens.onAccent;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tokens.accent, tokens.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => ref
              .read(playerControllerProvider.notifier)
              .playTrack(track, queue: [track]),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: onGradient,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '#1 MOST PLAYED $periodLabel',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.auto_awesome, color: onGradient, size: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: track.localThumbnailPath != null &&
                              File(track.localThumbnailPath!).existsSync()
                          ? Image.file(
                              File(track.localThumbnailPath!),
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            )
                          : track.thumbnailUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: track.thumbnailUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _fallback96(tokens),
                                )
                              : _fallback96(tokens),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onGradient,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onGradient.withValues(alpha: 0.72),
                            ),
                          ),
                          if (track.album != null)
                            Text(
                              track.album!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onGradient.withValues(alpha: 0.6),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: onGradient.withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              '$count× diputar',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: onGradient,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _fallback96(AppColorTokens tokens) => Container(
        width: 96,
        height: 96,
        color: tokens.onAccent.withValues(alpha: 0.24),
        child: Icon(Icons.music_note, color: tokens.onAccent, size: 48),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final int rank;
  final Track track;
  final int count;
  final WidgetRef ref;
  final List<Track> queue;
  const _SongTile({
    required this.rank,
    required this.track,
    required this.count,
    required this.ref,
    required this.queue,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final playerTrack = ref.watch(playerControllerProvider).currentTrack;
    final isPlaying = playerTrack?.sourceId == track.sourceId;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        tileColor: isPlaying ? tokens.row : tokens.surface,
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: track.localThumbnailPath != null &&
                      File(track.localThumbnailPath!).existsSync()
                  ? Image.file(
                      File(track.localThumbnailPath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : track.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.thumbnailUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _thumbFallback(tokens),
                        )
                      : _thumbFallback(tokens),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: rank == 1 ? tokens.accent : tokens.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank == 1 ? tokens.onAccent : tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isPlaying ? tokens.accent : tokens.textPrimary,
          ),
        ),
        subtitle: Text(
          '${track.artist} • ${_fmt(track.durationMs)} • $count×',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        trailing: isPlaying
            ? Icon(Icons.equalizer, color: tokens.accent)
            : Text(
                '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textInactive,
                  fontWeight: FontWeight.bold,
                ),
              ),
        onTap: () => ref
            .read(playerControllerProvider.notifier)
            .playTrack(track, queue: queue),
      ),
    );
  }

  Widget _thumbFallback(AppColorTokens tokens) => Container(
        width: 56,
        height: 56,
        color: tokens.raised,
        child: Icon(Icons.music_note, color: tokens.textInactive),
      );
}

class _ArtistTile extends StatelessWidget {
  final int rank;
  final ArtistCount data;
  const _ArtistTile({required this.rank, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        tileColor: tokens.surface,
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.raised,
                shape: BoxShape.circle,
                image: data.thumbLocal != null &&
                        File(data.thumbLocal!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(data.thumbLocal!)),
                        fit: BoxFit.cover,
                      )
                    : data.thumb != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(data.thumb!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (data.thumbLocal == null ||
                          !File(data.thumbLocal!).existsSync()) &&
                      data.thumb == null
                  ? Icon(Icons.person, color: tokens.textInactive)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: tokens.background,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: Text(
          '${data.count}× diputar',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.raised,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
    final tokens = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        tileColor: tokens.surface,
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: data.thumbLocal != null &&
                      File(data.thumbLocal!).existsSync()
                  ? Image.file(
                      File(data.thumbLocal!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : data.thumb != null
                      ? CachedNetworkImage(
                          imageUrl: data.thumb!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _thumbFallback(tokens),
                        )
                      : _thumbFallback(tokens),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          data.album,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: Text(
          '${data.artist} • ${data.count}×',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        trailing: Icon(Icons.album, color: tokens.textInactive, size: 20),
      ),
    );
  }

  Widget _thumbFallback(AppColorTokens tokens) => Container(
        width: 56,
        height: 56,
        color: tokens.raised,
        child: Icon(Icons.album, color: tokens.textInactive),
      );
}
