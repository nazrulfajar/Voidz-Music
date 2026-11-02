import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Artwork with the single fallback used across the app.
///
/// Order: local file → network image → monochrome gradient placeholder.
class AppArtwork extends StatelessWidget {
  const AppArtwork({
    super.key,
    this.localPath,
    this.imageUrl,
    required this.size,
    this.radius = AppRadius.md,
    this.icon = Icons.music_note_rounded,
    this.iconSize,
    this.border = false,
  });

  final String? localPath;
  final String? imageUrl;
  final double size;
  final double radius;
  final IconData icon;
  final double? iconSize;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final radiusValue = BorderRadius.circular(radius);

    Widget fallback() {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.artworkGradient),
        child: Center(
          child: Icon(
            icon,
            size: iconSize ?? size * 0.32,
            color: tokens.textSecondary,
          ),
        ),
      );
    }

    Widget image;
    if (localPath != null && localPath!.isNotEmpty) {
      image = Image.file(
        File(localPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).round(),
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      );
    } else {
      image = fallback();
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radiusValue,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.well,
            borderRadius: radiusValue,
            border: border ? Border.all(color: tokens.focusedBorder) : null,
          ),
          child: image,
        ),
      ),
    );
  }
}
