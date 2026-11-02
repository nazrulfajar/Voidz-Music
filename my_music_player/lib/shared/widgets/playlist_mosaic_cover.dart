import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// Renders up to four artwork images in a 2×2 mosaic.
///
/// [size] is the legacy square side; [width]/[height] override it for
/// non-square covers such as the Daily Mix card. Fewer than four images falls
/// back to a single image or the default icon.
class PlaylistMosaicCover extends StatelessWidget {
  final List<String> imageUrls;
  final IconData defaultIcon;
  final Color? iconColor;
  final double size;
  final double? width;
  final double? height;

  const PlaylistMosaicCover({
    super.key,
    required this.imageUrls,
    this.defaultIcon = Icons.queue_music,
    this.iconColor,
    this.size = 120.0,
    this.width,
    this.height,
  });

  double get _resolvedWidth => width ?? size;
  double get _resolvedHeight => height ?? size;

  Widget _buildImage(
    BuildContext context,
    String url, {
    double? width,
    double? height,
  }) {
    final tokens = AppColors.of(context);
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) =>
            ColoredBox(color: tokens.surface),
      );
    }
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          ColoredBox(color: tokens.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final resolvedWidth = _resolvedWidth;
    final resolvedHeight = _resolvedHeight;
    final resolvedIconColor = iconColor ?? tokens.textSecondary;

    if (imageUrls.isEmpty) {
      return Container(
        width: resolvedWidth,
        height: resolvedHeight,
        color: tokens.raised,
        child: Icon(
          defaultIcon,
          size: resolvedWidth * 0.5,
          color: resolvedIconColor.withValues(alpha: 0.8),
        ),
      );
    }

    if (imageUrls.length < 4) {
      return Container(
        width: resolvedWidth,
        height: resolvedHeight,
        color: tokens.surface,
        child: _buildImage(
          context,
          imageUrls.first,
          width: resolvedWidth,
          height: resolvedHeight,
        ),
      );
    }

    return Container(
      width: resolvedWidth,
      height: resolvedHeight,
      color: tokens.surface,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    context,
                    imageUrls[0],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: _buildImage(
                    context,
                    imageUrls[1],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    context,
                    imageUrls[2],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: _buildImage(
                    context,
                    imageUrls[3],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
