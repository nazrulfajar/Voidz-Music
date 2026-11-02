import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

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
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.offline_pin, color: t.textSecondary, size: 14),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: t.textSecondary),
      ),
      trailing: trailing ??
          (isPlaying ? Icon(Icons.equalizer, color: t.accent) : null),
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
