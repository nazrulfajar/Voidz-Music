import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/track.dart';
import '../../../lyrics/presentation/widgets/lyrics_view.dart';
import '../providers/player_controller.dart';
import '../widgets/queue_view.dart';
import '../widgets/sleep_timer_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Premium: push canonical detail without closing player, no tab-switch hack.
  // Player stays in stack so back returns to Now Playing (Spotify/Apple behavior).
  Future<void> _navigateToArtist(
      BuildContext context, WidgetRef ref, String artistName) async {
    if (artistName == 'Unknown Artist' || artistName.isEmpty) return;

    final isOnline = ref.read(connectivityProvider).value ?? true;
    if (!isOnline) {
      AppSnackbar.showError(context, 'Offline mode: Cannot load artist');
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService
          .searchArtistsOrAlbums(artistName, 'artists', limit: 1);

      if (context.mounted) Navigator.pop(context); // close loading

      if (results.isNotEmpty && results.first['browse_id'] != null) {
        final id = results.first['browse_id'];
        if (context.mounted) {
          // Premium: canonical push, player stays — no Navigator.pop(player)
          context.push('/artist/$id');
        }
      } else {
        if (context.mounted) {
          AppSnackbar.showError(context, 'Artist page not found');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showError(context, 'Failed to load artist: $e');
      }
    }
  }

  Future<void> _navigateToAlbum(BuildContext context, WidgetRef ref,
      String albumName, String artistName) async {
    if (albumName.isEmpty) return;

    final isOnline = ref.read(connectivityProvider).value ?? true;
    if (!isOnline) {
      AppSnackbar.showError(context, 'Offline mode: Cannot load album');
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService
          .searchArtistsOrAlbums('$albumName $artistName', 'albums', limit: 1);

      if (context.mounted) Navigator.pop(context); // close loading

      if (results.isNotEmpty && results.first['browse_id'] != null) {
        final id = results.first['browse_id'];
        if (context.mounted) {
          context.push('/album/$id');
        }
      } else {
        if (context.mounted) {
          AppSnackbar.showError(context, 'Album page not found');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showError(context, 'Failed to load album: $e');
      }
    }
  }

  void _showLyricsSheet(BuildContext context) {
    final t = AppColors.of(context);
    final mq = MediaQuery.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      builder: (_) {
        return SizedBox(
          height: mq.size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.handle),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Lyrics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(child: LyricsView()),
            ],
          ),
        );
      },
    );
  }

  void _showQueueSheet(BuildContext context) {
    final t = AppColors.of(context);
    final mq = MediaQuery.of(context);
    final queueLength = ref.read(playerControllerProvider).currentQueue.length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      builder: (_) {
        return SizedBox(
          height: mq.size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.handle),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Queue ($queueLength)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(child: QueueView()),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;
    final t = AppColors.of(context);

    ref.listen(playerControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackbar.showError(context, next.errorMessage!);
      }
    });

    if (currentTrack == null) {
      return Scaffold(
        backgroundColor: t.background,
        body: Center(
          child: CircularProgressIndicator(color: t.textPrimary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = (screenWidth - 48) < 312 ? (screenWidth - 48) : 312.0;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 420,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Header
                      Row(
                        children: [
                          AppIconButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            onPressed: () => context.pop(),
                            iconSize: 22,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PLAYING FROM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: t.textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentTrack.source.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'add_playlist') {
                                showAddToPlaylistSheet(context,
                                    track: currentTrack);
                              } else if (value == 'sleep_timer') {
                                showSleepTimerSheet(context);
                              }
                            },
                            color: t.panel,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'sleep_timer',
                                child: Text(
                                  'Sleep Timer',
                                  style: TextStyle(color: t.textPrimary),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'add_playlist',
                                child: Text(
                                  'Add to Playlist',
                                  style: TextStyle(color: t.textPrimary),
                                ),
                              ),
                            ],
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: t.raised,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.more_horiz,
                                size: 20,
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Artwork
                      Center(
                        child: DoubleTapArtwork(
                          track: currentTrack,
                          size: artworkSize,
                          onDoubleTap: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .toggleLike();
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Quality badge
                      if (currentTrack.audioFormat != null ||
                          currentTrack.bitrateKbps != null)
                        Center(
                          child: Container(
                            width: 170,
                            height: 27,
                            decoration: BoxDecoration(
                              color: t.background,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: t.qualityOutline),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              [
                                if (currentTrack.audioFormat != null)
                                  currentTrack.audioFormat!.toUpperCase(),
                                if (currentTrack.bitrateKbps != null)
                                  '${currentTrack.bitrateKbps} kbps',
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 10,
                                color: t.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTrack.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 34 / 28,
                                    color: t.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _navigateToArtist(
                                          context, ref, currentTrack.artist),
                                      child: Text(
                                        currentTrack.artist,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: t.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (currentTrack.album != null &&
                                        currentTrack.album!.isNotEmpty) ...[
                                      Text(
                                        '·',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: t.textSecondary,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _navigateToAlbum(
                                            context,
                                            ref,
                                            currentTrack.album!,
                                            currentTrack.artist),
                                        child: Text(
                                          currentTrack.album!,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: t.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(playerControllerProvider.notifier)
                                  .toggleLike();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: t.raised,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentTrack.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 21,
                                color: currentTrack.isLiked
                                    ? t.textPrimary
                                    : t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Seek
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: t.accent,
                            inactiveTrackColor: t.track,
                            thumbColor: t.accent,
                            trackHeight: 5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: playerState.position.inMilliseconds
                                .toDouble()
                                .clamp(
                                  0.0,
                                  playerState.duration.inMilliseconds > 0
                                      ? playerState.duration.inMilliseconds
                                          .toDouble()
                                      : 1.0,
                                ),
                            max: playerState.duration.inMilliseconds > 0
                                ? playerState.duration.inMilliseconds.toDouble()
                                : 1.0,
                            onChanged: (value) {
                              ref
                                  .read(playerControllerProvider.notifier)
                                  .seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(playerState.position),
                              style: TextStyle(
                                fontSize: 11,
                                color: t.textSecondary,
                              ),
                            ),
                            Text(
                              _formatDuration(playerState.duration),
                              style: TextStyle(
                                fontSize: 11,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                size: 21,
                                color: playerState.isShuffleEnabled
                                    ? t.textPrimary
                                    : t.textInactive,
                              ),
                              onPressed: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .toggleShuffle();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                size: 21,
                                color: t.textPrimary,
                              ),
                              onPressed: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playPrevious();
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .togglePlayPause();
                              },
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: t.accent,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.playButton),
                                ),
                                child: Icon(
                                  playerState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: t.onAccent,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_next_rounded,
                                size: 21,
                                color: t.textPrimary,
                              ),
                              onPressed: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playNext();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                playerState.loopMode == LoopMode.one
                                    ? Icons.repeat_one
                                    : Icons.repeat,
                                size: 21,
                                color: playerState.loopMode != LoopMode.off
                                    ? t.textPrimary
                                    : t.textInactive,
                              ),
                              onPressed: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .toggleRepeat();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Dock
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: t.row,
                          borderRadius: BorderRadius.circular(AppRadius.x4xl),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DockItem(
                                icon: Icons.lyrics_outlined,
                                label: 'Lyrics',
                                color: t.textSecondary,
                                onTap: () => _showLyricsSheet(context),
                              ),
                            ),
                            Expanded(
                              child: _DockItem(
                                icon: Icons.queue_music_rounded,
                                label:
                                    'Queue (${playerState.currentQueue.length})',
                                color: t.textSecondary,
                                onTap: () => _showQueueSheet(context),
                              ),
                            ),
                            Expanded(
                              child: _DockItem(
                                icon: Icons.timer_outlined,
                                label: 'Timer',
                                color: t.textSecondary,
                                onTap: () => showSleepTimerSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.x4xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DoubleTapArtwork extends StatefulWidget {
  const DoubleTapArtwork({
    super.key,
    required this.track,
    required this.size,
    required this.onDoubleTap,
  });

  final Track track;
  final double size;
  final VoidCallback onDoubleTap;

  @override
  State<DoubleTapArtwork> createState() => _DoubleTapArtworkState();
}

class _DoubleTapArtworkState extends State<DoubleTapArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppArtwork(
            localPath: widget.track.localThumbnailPath,
            imageUrl: widget.track.thumbnailUrl,
            size: widget.size,
            radius: AppRadius.x4xl,
            border: true,
          ),
          // Heart Animation Overlay
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.isDismissed) return const SizedBox.shrink();
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Icon(
                    Icons.favorite,
                    color: t.textPrimary,
                    size: 120,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
