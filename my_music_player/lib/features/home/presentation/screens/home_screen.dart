import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/home_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  final List<String> _moods = [
    'All',
    'Energize',
    'Workout',
    'Relax',
    'Commute',
    'Focus',
    'Podcasts'
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final quickPicksAsync = ref.watch(quickPicksProvider);
    final selectedMood = ref.watch(homeMoodProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Animated Blurred Background
          recentlyPlayedAsync.maybeWhen(
            data: (tracks) {
              if (tracks.isEmpty) {
                return Container(color: AppColors.surfaceBase);
              }

              final imageUrls = tracks
                  .take(4)
                  .map((t) => t.thumbnailUrl)
                  .whereType<String>()
                  .toList();
              if (imageUrls.isEmpty) {
                return Container(color: AppColors.surfaceBase);
              }

              return Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.5,
                      child: Transform.rotate(
                        angle: _bgAnimationController.value * 2 * math.pi,
                        child: Opacity(
                          opacity: 0.6,
                          child: PlaylistMosaicCover(
                            imageUrls: imageUrls,
                            size: MediaQuery.of(context).size.height,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            orElse: () => Container(color: AppColors.surfaceBase),
          ),

          // Heavy Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceBase.withValues(alpha: 0.3),
                      AppColors.surfaceBase.withValues(alpha: 0.8),
                      AppColors.surfaceBase.withValues(alpha: 1.0),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(quickPicksProvider);
                try {
                  await ref.read(recentlyPlayedProvider.future);
                  await ref.read(quickPicksProvider.future);
                } catch (_) {}
              },
              color: AppColors.accentPrimary,
              backgroundColor: AppColors.surfaceElevated,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    title: Text(
                      _getGreeting(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        height: 60,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          itemCount: _moods.length,
                          itemBuilder: (context, index) {
                            final mood = _moods[index];
                            final isSelected = selectedMood == mood;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: ChoiceChip(
                                label: Text(mood),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref.read(homeMoodProvider.notifier).state =
                                        mood;
                                  } else if (!selected && isSelected) {
                                    ref.read(homeMoodProvider.notifier).state =
                                        'All';
                                  }
                                },
                                backgroundColor: AppColors.surfaceElevated
                                    .withValues(alpha: 0.4),
                                selectedColor: AppColors.textPrimary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.surfaceBase
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.white24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!isOnline)
                    SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.statusError.withValues(alpha: 0.2),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off,
                                color: AppColors.statusError, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Offline Mode',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: AppColors.statusError),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Section (Your Daily Mix)
                          recentlyPlayedAsync.when(
                            data: (tracks) {
                              if (tracks.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final mixTracks = tracks.take(4).toList();
                              final imageUrls = mixTracks
                                  .map((t) => t.thumbnailUrl)
                                  .whereType<String>()
                                  .toList();

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(playerControllerProvider.notifier)
                                        .playTrack(tracks.first, queue: tracks);
                                  },
                                  child: Container(
                                    height: 220,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.xl),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Background
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xl),
                                          child: imageUrls.isNotEmpty
                                              ? PlaylistMosaicCover(
                                                  imageUrls: imageUrls,
                                                  size: 400)
                                              : Container(
                                                  color: AppColors
                                                      .surfaceElevated),
                                        ),
                                        // Gradient Overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.xl),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black
                                                    .withValues(alpha: 0.6),
                                                Colors.black
                                                    .withValues(alpha: 0.9),
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(
                                              AppSpacing.lg),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'STATION FOR YOU',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  letterSpacing: 1.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: AppSpacing.xs),
                                              Text(
                                                'Your Daily Mix',
                                                style: theme
                                                    .textTheme.headlineMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: AppSpacing.xs),
                                              Text(
                                                'Based on your recent listening',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Play Button
                                        Positioned(
                                          bottom: AppSpacing.lg,
                                          right: AppSpacing.lg,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: AppColors.accentPrimary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.play_arrow,
                                                  color: AppColors.textOnAccent,
                                                  size: 32),
                                              onPressed: () {
                                                final shuffled = List.of(tracks)
                                                  ..shuffle();
                                                ref
                                                    .read(
                                                        playerControllerProvider
                                                            .notifier)
                                                    .playTrack(shuffled.first,
                                                        queue: shuffled);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: ShimmerSection(itemCount: 1),
                            ),
                            error: (e, st) => const SizedBox.shrink(),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Listen Again (Recently Played)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recently Played',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          SizedBox(
                            height: 180,
                            child: recentlyPlayedAsync.when(
                              data: (tracks) {
                                if (tracks.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg),
                                    child: Text('No recent activity',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  );
                                }
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  itemCount: tracks.length,
                                  itemBuilder: (context, index) {
                                    final track = tracks[index];
                                    return GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(playerControllerProvider
                                                .notifier)
                                            .playTrack(track, queue: [track]);
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(
                                            right: AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                              child: track.localThumbnailPath !=
                                                      null
                                                  ? Image.file(File(track.localThumbnailPath!),
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) =>
                                                          const ColoredBox(
                                                              color: AppColors
                                                                  .surfaceElevated))
                                                  : CachedNetworkImage(
                                                      imageUrl:
                                                          track.thumbnailUrl ??
                                                              '',
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (c, u, e) =>
                                                          const ColoredBox(
                                                              color: AppColors
                                                                  .surfaceElevated)),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            Text(track.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                            Text(track.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: AppColors
                                                            .textSecondary)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: ShimmerSection(itemCount: 3),
                              ),
                              error: (e, st) => const SizedBox.shrink(),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Quick Picks (Horizontal Grid)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Text(
                              selectedMood == 'All'
                                  ? 'Quick Picks'
                                  : '$selectedMood Mix',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          quickPicksAsync.when(
                            data: (tracks) {
                              if (tracks.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  child: Text('Nothing to suggest right now',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                );
                              }

                              // Split tracks into chunks of 4
                              const int itemsPerColumn = 4;
                              final int numColumns =
                                  (tracks.length / itemsPerColumn).ceil();

                              return SizedBox(
                                height:
                                    290, // 4 items * (~64 height + 8 padding)
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  itemCount: numColumns,
                                  itemBuilder: (context, colIndex) {
                                    final startIndex =
                                        colIndex * itemsPerColumn;
                                    final endIndex = math.min(
                                        startIndex + itemsPerColumn,
                                        tracks.length);
                                    final columnTracks =
                                        tracks.sublist(startIndex, endIndex);

                                    return Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.85,
                                      padding: const EdgeInsets.only(
                                          right: AppSpacing.md),
                                      child: Column(
                                        children: columnTracks.map((track) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.sm),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Ink(
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .surfaceElevated
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.md),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    ref
                                                        .read(
                                                            playerControllerProvider
                                                                .notifier)
                                                        .playTrack(track,
                                                            queue: [track]);
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.md),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            AppSpacing.xs),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 56,
                                                          height: 56,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColors
                                                                .surfaceOverlay,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        AppRadius
                                                                            .sm),
                                                            image: (track
                                                                        .localThumbnailPath !=
                                                                    null)
                                                                ? DecorationImage(
                                                                    image: FileImage(
                                                                        File(track
                                                                            .localThumbnailPath!)),
                                                                    fit: BoxFit
                                                                        .cover)
                                                                : (track.thumbnailUrl !=
                                                                        null)
                                                                    ? DecorationImage(
                                                                        image: CachedNetworkImageProvider(track
                                                                            .thumbnailUrl!),
                                                                        fit: BoxFit
                                                                            .cover)
                                                                    : null,
                                                          ),
                                                          child: (track.localThumbnailPath ==
                                                                      null &&
                                                                  track.thumbnailUrl ==
                                                                      null)
                                                              ? const Icon(
                                                                  Icons
                                                                      .music_note,
                                                                  color: AppColors
                                                                      .textTertiary)
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                            width:
                                                                AppSpacing.md),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                        track
                                                                            .title,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        style: theme
                                                                            .textTheme
                                                                            .bodyLarge
                                                                            ?.copyWith(fontWeight: FontWeight.w600)),
                                                                  ),
                                                                  if (track
                                                                      .isCached) ...[
                                                                    const SizedBox(
                                                                        width: AppSpacing
                                                                            .xs),
                                                                    const Icon(
                                                                        Icons
                                                                            .offline_pin,
                                                                        color: AppColors
                                                                            .statusSuccess,
                                                                        size:
                                                                            14),
                                                                  ],
                                                                ],
                                                              ),
                                                              Text(track.artist,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: const TextStyle(
                                                                      color: AppColors
                                                                          .textSecondary)),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.more_vert,
                                                              color: AppColors
                                                                  .textSecondary),
                                                          onPressed: () {},
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: ShimmerSection(itemCount: 5),
                            ),
                            error: (e, st) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: Text('Error: $e',
                                  style: const TextStyle(
                                      color: AppColors.statusError)),
                            ),
                          ),
                          const SizedBox(
                              height: 160), // Padding for bottom player
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
