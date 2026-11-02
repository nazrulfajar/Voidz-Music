import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:marquee/marquee.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../providers/player_controller.dart';
import '../widgets/queue_view.dart';
import '../../../lyrics/presentation/widgets/lyrics_view.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../widgets/sleep_timer_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Color _dominantColor = AppColors.surfaceBase;
  Color _vibrantColor = AppColors.accentPrimary;
  Color _titleTextColor = Colors.white;
  Color _bodyTextColor = Colors.white70;
  String? _lastImageUrl;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Make status bar transparent when player is open (like Spotify/Apple Music)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore status bar style when leaving player
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  // Cache palette agar tidak re-generate tiap track yang sama (local lag)
  final Map<String, PaletteGenerator> _paletteCache = {};

  Future<void> _updatePalette(String? imageUrl, String? localPath) async {
    if (imageUrl == null && localPath == null) return;
    final cacheKey = localPath ?? imageUrl!;
    if (cacheKey == _lastImageUrl) return;
    _lastImageUrl = cacheKey;
    if (_paletteCache.containsKey(cacheKey)) {
      final cached = _paletteCache[cacheKey]!;
      if (mounted) {
        setState(() {
          Color dColor = cached.dominantColor?.color ?? AppColors.surfaceBase;
          HSLColor hsl = HSLColor.fromColor(dColor);
          if (hsl.lightness > 0.4) dColor = hsl.withLightness(0.4).toColor();
          _dominantColor = dColor;
          _vibrantColor = cached.vibrantColor?.color ?? AppColors.accentPrimary;
        });
      }
      return;
    }

    try {
      final ImageProvider imageProvider;
      // Ponytail: tanpa existsSync (lag) — langsung coba FileImage, error akan ditangani catch
      if (localPath != null) {
        imageProvider = FileImage(File(localPath));
      } else if (imageUrl != null) {
        imageProvider = CachedNetworkImageProvider(imageUrl);
      } else {
        return;
      }

      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(80, 80),
        maximumColorCount: 12,
      );
      _paletteCache[cacheKey] = generator;

      if (mounted) {
        setState(() {
          Color dColor =
              generator.dominantColor?.color ?? AppColors.surfaceBase;
          HSLColor hsl = HSLColor.fromColor(dColor);
          if (hsl.lightness > 0.4) {
            dColor = hsl.withLightness(0.4).toColor();
          }
          _dominantColor = dColor;
          _vibrantColor =
              generator.vibrantColor?.color ?? AppColors.accentPrimary;
          _titleTextColor = Colors
              .white; // We can force white since background is always dark
          _bodyTextColor = Colors.white70;
        });
      }
    } catch (e) {
      print('Palette generation error: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;
    final theme = Theme.of(context);

    ref.listen(playerControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackbar.showError(context, next.errorMessage!);
      }

      // Update palette when track changes
      if (next.currentTrack?.sourceId != previous?.currentTrack?.sourceId) {
        _updatePalette(next.currentTrack?.thumbnailUrl,
            next.currentTrack?.localThumbnailPath);
      }
    });

    // Initial palette load
    if (currentTrack != null && _lastImageUrl == null) {
      _updatePalette(
          currentTrack.thumbnailUrl, currentTrack.localThumbnailPath);
    }

    if (currentTrack == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceBase,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _dominantColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 36, color: _titleTextColor),
          onPressed: () {
            if (_isFullScreen) {
              setState(() => _isFullScreen = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NOW PLAYING',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2.0,
                color: _bodyTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentTrack.source.name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _titleTextColor.withValues(alpha: 0.8),
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _titleTextColor),
            color: AppColors.surfaceElevated,
            onSelected: (value) {
              if (value == 'add_playlist') {
                showAddToPlaylistSheet(context, track: currentTrack);
              } else if (value == 'sleep_timer') {
                showSleepTimerSheet(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sleep_timer',
                child: Text('Sleep Timer',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'add_playlist',
                child: Text('Add to Playlist',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ],
      ),
      body: PopScope(
        canPop: !_isFullScreen,
        onPopInvoked: (didPop) {
          if (!didPop && _isFullScreen) {
            setState(() => _isFullScreen = false);
          }
        },
        child: Stack(
          children: [
            // Background blurred image — ponytail: tanpa existsSync, blur 18 (dari 60) + RepaintBoundary agar GPU tidak lag local
            Positioned.fill(
              child: RepaintBoundary(
                child: currentTrack.localThumbnailPath != null
                    ? Image.file(
                        File(currentTrack.localThumbnailPath!),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (_, __, ___) => CachedNetworkImage(
                          imageUrl: currentTrack.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: _dominantColor),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: currentTrack.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        errorWidget: (context, url, error) =>
                            Container(color: _dominantColor),
                      ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _dominantColor.withValues(alpha: 0.5),
                          _dominantColor.withValues(alpha: 0.8),
                          AppColors.surfaceBase.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            height: _isFullScreen
                                ? kToolbarHeight - 48
                                : AppSpacing.md),
                        if (_isFullScreen)
                          GestureDetector(
                            onVerticalDragUpdate: (details) {
                              if (details.delta.dy > 5) {
                                setState(() => _isFullScreen = false);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: currentTrack.localThumbnailPath != null
                                        ? Image.file(
                                            File(currentTrack
                                                .localThumbnailPath!),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            cacheWidth: 120,
                                            errorBuilder: (_, __, ___) =>
                                                CachedNetworkImage(
                                              imageUrl:
                                                  currentTrack.thumbnailUrl ?? '',
                                              width: 56,
                                              height: 56,
                                              memCacheWidth: 120,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.music_note,
                                                          size: 56),
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl:
                                                currentTrack.thumbnailUrl ?? '',
                                            width: 56,
                                            height: 56,
                                            memCacheWidth: 120,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.music_note,
                                                        size: 56),
                                          ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentTrack.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: _titleTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentTrack.artist,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: _bodyTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutQuart,
                          child: _isFullScreen
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  children: [
                                    // Artwork
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xxl),
                                      child: Hero(
                                        tag: AppAnimations.heroArtwork(
                                            currentTrack.sourceId),
                                        child: DoubleTapArtwork(
                                          track: currentTrack,
                                          shadowColor: _vibrantColor,
                                          onDoubleTap: () {
                                            ref
                                                .read(playerControllerProvider
                                                    .notifier)
                                                .toggleLike();
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: AppSpacing.xl),

                                    // Audio Quality Badge
                                    if (currentTrack.audioFormat != null ||
                                        currentTrack.bitrateKbps != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                            left: AppSpacing.xl,
                                            right: AppSpacing.xl),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.white24,
                                                    width: 0.5),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.high_quality,
                                                      size: 12,
                                                      color: Colors.white70),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    [
                                                      if (currentTrack
                                                              .audioFormat !=
                                                          null)
                                                        currentTrack
                                                            .audioFormat!
                                                            .toUpperCase(),
                                                      if (currentTrack
                                                              .bitrateKbps !=
                                                          null)
                                                        '${currentTrack.bitrateKbps} kbps'
                                                    ].join(' • '),
                                                    style: theme
                                                        .textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Track Info
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xl),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 32,
                                                  child: currentTrack
                                                              .title.length >
                                                          25
                                                      ? Marquee(
                                                          text: currentTrack
                                                              .title,
                                                          style: theme.textTheme
                                                              .displayMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                _titleTextColor,
                                                          ),
                                                          scrollAxis:
                                                              Axis.horizontal,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          blankSpace: 20.0,
                                                          velocity: 30.0,
                                                        )
                                                      : Text(
                                                          currentTrack.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: theme.textTheme
                                                              .displayMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                _titleTextColor,
                                                          ),
                                                        ),
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xs),
                                                SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _navigateToArtist(
                                                                context,
                                                                ref,
                                                                currentTrack
                                                                    .artist),
                                                        child: Text(
                                                          currentTrack.artist,
                                                          style: theme.textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                            color:
                                                                _bodyTextColor,
                                                          ),
                                                        ),
                                                      ),
                                                      if (currentTrack.album !=
                                                              null &&
                                                          currentTrack.album!
                                                              .isNotEmpty) ...[
                                                        Text(
                                                          ' • ',
                                                          style: theme.textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                            color: _bodyTextColor
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () =>
                                                              _navigateToAlbum(
                                                                  context,
                                                                  ref,
                                                                  currentTrack
                                                                      .album!,
                                                                  currentTrack
                                                                      .artist),
                                                          child: Text(
                                                            currentTrack.album!,
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                              color:
                                                                  _bodyTextColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              currentTrack.isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: currentTrack.isLiked
                                                  ? _vibrantColor
                                                  : _titleTextColor,
                                              size: 28,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .toggleLike();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: AppSpacing.lg),

                                    // Slider
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md),
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: Colors.white,
                                          trackHeight: 4.0,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6.0),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                  overlayRadius: 16.0),
                                        ),
                                        child: Slider(
                                          value: playerState
                                              .position.inMilliseconds
                                              .toDouble()
                                              .clamp(
                                                  0.0,
                                                  playerState.duration
                                                              .inMilliseconds >
                                                          0
                                                      ? playerState.duration
                                                          .inMilliseconds
                                                          .toDouble()
                                                      : 1.0),
                                          max: playerState
                                                      .duration.inMilliseconds >
                                                  0
                                              ? playerState
                                                  .duration.inMilliseconds
                                                  .toDouble()
                                              : 1.0,
                                          onChanged: (value) {
                                            ref
                                                .read(playerControllerProvider
                                                    .notifier)
                                                .seek(Duration(
                                                    milliseconds:
                                                        value.toInt()));
                                          },
                                        ),
                                      ),
                                    ),

                                    // Time Labels
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xl),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(
                                                playerState.position),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                    color: Colors.white54),
                                          ),
                                          Text(
                                            _formatDuration(
                                                playerState.duration),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                    color: Colors.white54),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: AppSpacing.sm),

                                    // Controls
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.shuffle,
                                              color:
                                                  playerState.isShuffleEnabled
                                                      ? _vibrantColor
                                                      : Colors.white54,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .toggleShuffle();
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.skip_previous_rounded,
                                                size: 48,
                                                color: _titleTextColor),
                                            onPressed: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .playPrevious();
                                            },
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .togglePlayPause();
                                            },
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _titleTextColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _titleTextColor
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                playerState.isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                size: 48,
                                                color: _dominantColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.skip_next_rounded,
                                                size: 48,
                                                color: _titleTextColor),
                                            onPressed: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .playNext();
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              playerState.loopMode ==
                                                      LoopMode.one
                                                  ? Icons.repeat_one
                                                  : Icons.repeat,
                                              color: playerState.loopMode !=
                                                      LoopMode.off
                                                  ? _vibrantColor
                                                  : Colors.white54,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(playerControllerProvider
                                                      .notifier)
                                                  .toggleRepeat();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),

                                    // Tab Indicators
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildDot(0, 'Up Next'),
                                        const SizedBox(width: AppSpacing.lg),
                                        _buildDot(1, 'Lyrics'),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ),
                        ),

                        // Swipeable PageView
                        NotificationListener<ScrollUpdateNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.axis == Axis.vertical) {
                              // Only trigger if it's a manual user scroll (dragDetails != null)
                              if (notification.dragDetails != null &&
                                  notification.scrollDelta != null) {
                                if (notification.scrollDelta! > 5 &&
                                    !_isFullScreen) {
                                  setState(() => _isFullScreen = true);
                                }
                              }
                            }
                            return false;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutQuart,
                            height: _isFullScreen
                                ? constraints.maxHeight - 120
                                : MediaQuery.of(context).size.height * 0.45,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              children: const [
                                QueueView(),
                                LyricsView(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, String label) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class DoubleTapArtwork extends StatefulWidget {
  final dynamic track;
  final VoidCallback onDoubleTap;
  final Color shadowColor;

  const DoubleTapArtwork({
    super.key,
    required this.track,
    required this.onDoubleTap,
    this.shadowColor = AppColors.accentPrimary,
  });

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
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
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
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AspectRatio(
                aspectRatio: 1,
                child: widget.track.localThumbnailPath != null
                    ? Image.file(
                        File(widget.track.localThumbnailPath!),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (_, __, ___) => CachedNetworkImage(
                          imageUrl: widget.track.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceOverlay,
                            child: const Icon(Icons.music_note,
                                size: 80, color: AppColors.textTertiary),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.track.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceOverlay,
                          child: const Icon(Icons.music_note,
                              size: 80, color: AppColors.textTertiary),
                        ),
                      ),
              ),
            ),
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
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
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
