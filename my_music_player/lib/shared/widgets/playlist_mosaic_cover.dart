import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

class PlaylistMosaicCover extends StatelessWidget {
  final List<String> imageUrls;
  final IconData defaultIcon;
  final Color? iconColor;
  final double size;

  const PlaylistMosaicCover({
    super.key,
    required this.imageUrls,
    this.defaultIcon = Icons.queue_music,
    this.iconColor,
    this.size = 120.0,
  });

  Widget _buildImage(
    AppColorTokens tokens,
    String url, {
    double? width,
    double? height,
  }) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) =>
            Container(color: tokens.well),
      );
    } else {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: tokens.well),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final resolvedIconColor = iconColor ?? tokens.textSecondary;

    if (imageUrls.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: tokens.well,
        child: Icon(
          defaultIcon,
          size: size * 0.5,
          color: resolvedIconColor.withValues(alpha: 0.8),
        ),
      );
    }

    if (imageUrls.length < 4) {
      return Container(
        width: size,
        height: size,
        color: tokens.well,
        child: _buildImage(tokens, imageUrls.first, width: size, height: size),
      );
    }

    return Container(
      width: size,
      height: size,
      color: tokens.well,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    tokens,
                    imageUrls[0],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: _buildImage(
                    tokens,
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
                    tokens,
                    imageUrls[2],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: _buildImage(
                    tokens,
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
