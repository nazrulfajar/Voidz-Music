import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Single source of truth untuk 48-thumb track row — dipakai di search,
/// artist topSongs, album, playlist, queue, library list.
/// Menggantikan 6 duplikat ListTile di search_screen, artist_screen,
/// album_screen, playlist_screen, dll.
class AppTrackTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final String? localThumbnailPath;
  final bool isPlaying;
  final bool isCached;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? leadingCustom; // untuk nomor urut album

  const AppTrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.isPlaying = false,
    this.isCached = false,
    this.trailing,
    this.onTap,
    this.leadingCustom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    // Ponytail: tanpa File.existsSync di build (lag). Langsung coba FileImage;
    // errorBuilder fallback ke icon.
    Widget thumbWidget;
    if (leadingCustom != null) {
      thumbWidget = leadingCustom!;
    } else {
      final hasLocal =
          localThumbnailPath != null && localThumbnailPath!.isNotEmpty;
      final hasRemote = thumbnailUrl != null && thumbnailUrl!.isNotEmpty;
      if (hasLocal) {
        thumbWidget = ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.file(
            File(localThumbnailPath!),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            cacheWidth: 100,
            errorBuilder: (_, __, ___) => _thumbFallback(t),
          ),
        );
      } else if (hasRemote) {
        thumbWidget = ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl!,
            width: 48,
            height: 48,
            memCacheWidth: 100,
            fit: BoxFit.cover,
            placeholder: (_, __) => _thumbFallback(t),
            errorWidget: (_, __, ___) => _thumbFallback(t),
          ),
        );
      } else {
        thumbWidget = _thumbFallback(t);
      }
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      tileColor: isPlaying ? t.well : null,
      hoverColor: t.well,
      leading: thumbWidget,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                color: isPlaying ? t.accent : t.textPrimary,
              ),
            ),
          ),
          if (isCached) ...[
            const SizedBox(width: AppSpacing.xxs),
            Semantics(
              label: l10n.commonDownloaded,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.offline_pin,
                  color: t.textSecondary,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: t.textSecondary),
            ),
          ),
          if (isPlaying) ...[
            const SizedBox(width: AppSpacing.xs),
            const NowPlayingBadge(),
          ],
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _thumbFallback(AppColorTokens t) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: t.raised,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(Icons.music_note, color: t.textMuted),
    );
  }
}

/// Equalizer icon plus a visible "Now playing" label.
///
/// The icon is decorative and carries no semantics of its own; the badge is
/// announced once as a status. The icon is static, so reduced-motion users see
/// the same non-animated affordance (`DESIGN_SYSTEM.md` §10).
class NowPlayingBadge extends StatelessWidget {
  const NowPlayingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.commonNowPlaying,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.equalizer,
              size: 14,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            l10n.commonNowPlaying,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal card 140×140 dipakai di artist albums/playlists — juga single
/// source.
class AppHorizontalCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const AppHorizontalCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    this.fallbackIcon = Icons.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: t.raised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: thumbnailUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: thumbnailUrl == null
                  ? Icon(fallbackIcon, size: 40, color: t.textSecondary)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: t.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
