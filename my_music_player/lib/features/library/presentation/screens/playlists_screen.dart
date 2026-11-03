import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_chrome_insets.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/create_playlist_dialog.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlist_provider.dart';

enum _PlaylistAction { create }

/// Screen 06 — the full grid of user-created playlists.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: AppSpacing.space4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _Header(
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/library');
                      }
                    },
                    onMore: () => _showMoreActions(context, ref),
                  ),
                  Expanded(
                    child: playlistsAsync.when(
                      data: (playlists) => _PlaylistsBody(
                        playlists: playlists
                            .where((playlist) => !playlist.isSystem)
                            .toList(),
                        onCreate: () => showCreatePlaylistDialog(context, ref),
                      ),
                      loading: () => Center(
                        child: CircularProgressIndicator(color: tokens.accent),
                      ),
                      error: (error, stackTrace) => AppErrorState(
                        error: l10n.playlistsLoadError,
                        onRetry: () => ref.invalidate(allPlaylistsProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreActions(BuildContext context, WidgetRef ref) async {
    final tokens = AppColors.of(context);
    final action = await showModalBottomSheet<_PlaylistAction>(
      context: context,
      backgroundColor: tokens.row,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      builder: (sheetContext) {
        final sheetTokens = AppColors.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.add_rounded,
                  color: sheetTokens.textPrimary,
                ),
                title: Text(
                  l10n.playlistsNew,
                  style: TextStyle(color: sheetTokens.textPrimary),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _PlaylistAction.create,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (action == _PlaylistAction.create && context.mounted) {
      await showCreatePlaylistDialog(context, ref);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          semanticLabel: l10n.commonBack,
          onPressed: onBack,
          iconSize: 18,
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Text(
            l10n.playlistsTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        AppIconButton(
          icon: Icons.more_horiz_rounded,
          semanticLabel: l10n.commonMoreOptions,
          onPressed: onMore,
          iconSize: 24,
        ),
      ],
    );
  }
}

class _PlaylistsBody extends StatelessWidget {
  const _PlaylistsBody({
    required this.playlists,
    required this.onCreate,
  });

  final List<Playlist> playlists;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space2,
            bottom: AppSpacing.space3,
          ),
          child: Text(
            l10n.commonPlaylistCount(playlists.length),
            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
          ),
        ),
        _NewPlaylistRow(onTap: onCreate),
        AppSectionHeader(
          title: l10n.playlistsTitle,
          padding: const EdgeInsets.fromLTRB(
            0,
            AppSpacing.space5,
            0,
            AppSpacing.space2,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.only(
              bottom: AppChromeInsets.bottomOf(context),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.space3,
              mainAxisSpacing: AppSpacing.space3,
              childAspectRatio: 0.82,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) => _PlaylistCard(
              playlist: playlists[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _NewPlaylistRow extends StatelessWidget {
  const _NewPlaylistRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GlassSurface.card(
      key: const Key('playlists-new-glass'),
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.raised,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      l10n.playlistsNew,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GlassSurface.card(
      key: ValueKey('playlists-card-glass-${playlist.id}'),
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            '/playlist-detail/${playlist.id}',
            extra: playlist,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final coverSize = constraints.maxWidth - AppSpacing.space4;
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.space2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppRadius.artworkSmall,
                        ),
                        child: PlaylistMosaicCover(
                          imageUrls: playlist.thumbnailUrls,
                          defaultIcon: Icons.queue_music_rounded,
                          iconColor: tokens.textSecondary,
                          size: coverSize,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space3,
                  0,
                  AppSpacing.space3,
                  AppSpacing.space3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playlistMeta(playlist, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "N songs · X hr Y min" for a playlist card.
String playlistMeta(Playlist playlist, AppLocalizations l10n) {
  final count = playlist.trackCount;
  final songs = l10n.commonSongCount(count);
  final duration = count == 0
      ? l10n.playlistsDurationMinutes(0)
      : formatPlaylistDuration(playlist.totalDurationMs, l10n);
  return '$songs · $duration';
}

/// Formats a summed duration without padding (e.g. `1 hr 32 min`, `9 min`).
String formatPlaylistDuration(int milliseconds, AppLocalizations l10n) {
  final totalMinutes = milliseconds ~/ Duration.millisecondsPerMinute;
  if (totalMinutes < Duration.minutesPerHour) {
    return l10n.playlistsDurationMinutes(totalMinutes);
  }
  final hours = totalMinutes ~/ Duration.minutesPerHour;
  final minutes = totalMinutes % Duration.minutesPerHour;
  return l10n.playlistsDurationHoursMinutes(hours, minutes);
}
