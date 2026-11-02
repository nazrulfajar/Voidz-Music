import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/lyrics.dart';
import '../providers/lyrics_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeKey = GlobalKey();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;
    if (index == _lastActiveIndex) return;

    _lastActiveIndex = index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeKey.currentContext != null) {
        Scrollable.ensureVisible(
          _activeKey.currentContext!,
          alignment: 0.35, // Moved from 0.5 to lift it roughly 1 line higher
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Fallback for when jumping large distances (scrubbing)
        final double offset = index * 70.0;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentLyricsProvider);
    final parsedLyrics = ref.watch(parsedLyricsProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);

    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.type == LyricsType.notFound) {
          return Center(
            child: Text(
              'Lirik tidak ditemukan',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        if (lyrics.type == LyricsType.plain || parsedLyrics == null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              lyrics.plainLyrics ?? lyrics.syncedLyrics ?? 'Lirik kosong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),
          );
        }

        // Synced Lyrics
        final activeIndex =
            parsedLyrics.getActiveLineIndex(playerState.position);

        // Use a post-frame callback to avoid updating scroll during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (activeIndex != -1) {
            _scrollToActiveLine(activeIndex);
          }
        });

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 80.0,
            ),
            itemCount: parsedLyrics.lines.length,
            itemBuilder: (context, index) {
              final line = parsedLyrics.lines[index];
              final isActive = index == activeIndex;
              final isPassed = index < activeIndex;

              return GestureDetector(
                key: isActive ? _activeKey : null,
                onTap: () {
                  ref.read(playerControllerProvider.notifier).seek(line.time);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: isActive
                          ? Colors.white
                          : (isPassed
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.5)),
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      fontSize: isActive ? 34 : 28,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.left,
                    child: Text(line.text),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary)),
      error: (err, stack) => const Center(child: Text('Error: \$err')),
    );
  }
}
