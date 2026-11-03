import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/app_logger.dart';

final paletteProvider = FutureProvider.family<PaletteGenerator?, String>((ref, url) async {
  if (url.isEmpty) return null;
  try {
    final imageProvider = CachedNetworkImageProvider(url, errorListener: (err) => debugPrint('Image load failed: $err'));
    final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
    return paletteGenerator;
  } catch (e) {
    appLogger.d('Failed to generate palette: $e');
    return null;
  }
});
