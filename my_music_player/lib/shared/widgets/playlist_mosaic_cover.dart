import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

class PlaylistMosaicCover extends StatelessWidget {
  final List<String> imageUrls;
  final IconData defaultIcon;
  final Color iconColor;
  final double size;

  const PlaylistMosaicCover({
    super.key,
    required this.imageUrls,
    this.defaultIcon = Icons.queue_music,
    this.iconColor = AppColors.textSecondary,
    this.size = 120.0,
  });

  Widget _buildImage(String url, {double? width, double? height}) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) =>
            Container(color: AppColors.surfaceElevated),
      );
    } else {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.surfaceElevated),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: AppColors.surfaceOverlay,
        child: Icon(defaultIcon,
            size: size * 0.5, color: iconColor.withValues(alpha: 0.8)),
      );
    }

    if (imageUrls.length < 4) {
      return Container(
        width: size,
        height: size,
        color: AppColors.surfaceElevated,
        child: _buildImage(imageUrls.first, width: size, height: size),
      );
    }

    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceElevated,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _buildImage(imageUrls[0],
                        width: double.infinity, height: double.infinity)),
                Expanded(
                    child: _buildImage(imageUrls[1],
                        width: double.infinity, height: double.infinity)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _buildImage(imageUrls[2],
                        width: double.infinity, height: double.infinity)),
                Expanded(
                    child: _buildImage(imageUrls[3],
                        width: double.infinity, height: double.infinity)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
