import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../player/domain/entities/track.dart';
import '../providers/home_provider.dart';

class DailyMixScreen extends ConsumerWidget {
  const DailyMixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentlyAsync = ref.watch(recentlyPlayedProvider);
    final playerState = ref.watch(playerControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop())),
      body: Stack(children: [
        // Mosaic blur background from recently tracks
        recentlyAsync.maybeWhen(
          data: (tracks) => Positioned.fill(
            child: PlaylistMosaicCover(
                imageUrls: tracks
                    .take(4)
                    .map((t) => t.thumbnailUrl)
                    .whereType<String>()
                    .toList(),
                size: 400),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        Positioned.fill(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                    color: AppColors.surfaceBase.withValues(alpha: 0.7)))),
        SafeArea(
          child: recentlyAsync.when(
            data: (tracks) {
              if (tracks.isEmpty)
                return const AppEmptyState(
                    icon: Icons.queue_music,
                    title: 'No tracks yet',
                    subtitle: 'Play some songs first');
              final imageUrls = tracks
                  .take(4)
                  .map((t) => t.thumbnailUrl)
                  .whereType<String>()
                  .toList();
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  child: Row(children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ]),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: PlaylistMosaicCover(
                              imageUrls: imageUrls, size: 120)),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Your Daily Mix',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('${tracks.length} tracks • Based on recent',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.white70)),
                          const SizedBox(height: AppSpacing.md),
                          Row(children: [
                            ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(playerControllerProvider.notifier)
                                  .playTrack(tracks.first, queue: tracks),
                              icon: const Icon(Icons.play_arrow,
                                  color: AppColors.textOnAccent),
                              label: const Text('Play All',
                                  style: TextStyle(
                                      color: AppColors.textOnAccent,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.full))),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              onPressed: () {
                                final shuffled = List<Track>.of(tracks)
                                  ..shuffle();
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playTrack(shuffled.first, queue: shuffled);
                              },
                              icon: const Icon(Icons.shuffle,
                                  color: Colors.white),
                              style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surfaceOverlay),
                            ),
                          ]),
                        ])),
                  ]),
                ),
                const Divider(color: AppColors.surfaceOverlay),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.md,
                        bottom: AppSpacing.bottomPlayerPadding),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isPlaying =
                          track.sourceId == playerState.currentTrack?.sourceId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: track.thumbnailUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: track.thumbnailUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover)
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surfaceOverlay,
                                  child: const Icon(Icons.music_note)),
                        ),
                        title: Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: isPlaying
                                    ? AppColors.accentPrimary
                                    : AppColors.textPrimary,
                                fontWeight: isPlaying
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        subtitle: Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (isPlaying)
                            const Icon(Icons.equalizer,
                                color: AppColors.accentPrimary, size: 18),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: AppColors.textSecondary, size: 20),
                            color: AppColors.surfaceElevated,
                            onSelected: (v) async {
                              final ctrl =
                                  ref.read(playerControllerProvider.notifier);
                              if (v == 'play_next') {
                                await ctrl.addToQueue(track, playNext: true);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Added to Play Next')));
                              } else if (v == 'add_queue') {
                                await ctrl.addToQueue(track);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Added to Queue')));
                              }
                            },
                            itemBuilder: (c) => const [
                              PopupMenuItem(
                                  value: 'play_next',
                                  child: Text('Play Next',
                                      style: TextStyle(
                                          color: AppColors.textPrimary))),
                              PopupMenuItem(
                                  value: 'add_queue',
                                  child: Text('Add to Queue',
                                      style: TextStyle(
                                          color: AppColors.textPrimary))),
                            ],
                          ),
                        ]),
                        onTap: () => ref
                            .read(playerControllerProvider.notifier)
                            .playTrack(track, queue: tracks),
                      );
                    },
                  ),
                ),
              ]);
            },
            loading: () => const Center(child: ShimmerSection(itemCount: 8)),
            error: (e, st) => AppErrorState(
                error: e.toString(),
                onRetry: () => ref.invalidate(recentlyPlayedProvider)),
          ),
        ),
      ]),
    );
  }
}
