import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/library/data/repositories/playlist_repository_impl.dart';
import '../../features/library/presentation/providers/playlist_provider.dart';

/// Single reusable dialog — tidak duplikat di library_screen & add_to_playlist_sheet
Future<String?> showCreatePlaylistDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  try {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty) Navigator.pop(dialogContext, n);
            },
            child: const Text('Create', style: TextStyle(color: AppColors.accentPrimary)),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(playlistRepositoryProvider).createPlaylist(name.trim());
      ref.invalidate(allPlaylistsProvider);
      return name.trim();
    }
    return null;
  } finally {
    controller.dispose();
  }
}

/// Khusus add_to_playlist: create + add batch — tidak leak controller
Future<void> showCreateAndAddDialog(BuildContext context, WidgetRef ref, List<dynamic> tracks) async {
  final controller = TextEditingController();
  try {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('New Playlist'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Playlist name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () {
            final n = controller.text.trim();
            if (n.isNotEmpty) Navigator.pop(dialogContext, n);
          }, child: const Text('Create & Add', style: TextStyle(color: AppColors.accentPrimary))),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final playlist = await ref.read(playlistRepositoryProvider).createPlaylist(name.trim());
    final res = await ref.read(playlistRepositoryProvider).addTracksToPlaylist(playlist.id!, tracks.cast());
    ref.invalidate(allPlaylistsProvider);
    if (context.mounted) {
      Navigator.pop(context); // close bottom sheet
      final msg = res.added > 0
          ? (tracks.length == 1 ? 'Added to ${playlist.name}' : 'Added ${res.added} tracks to ${playlist.name}${res.existed > 0 ? ' (${res.existed} already existed)' : ''}')
          : 'Already in ${playlist.name}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)), backgroundColor: AppColors.surfaceOverlay));
    }
  } finally {
    controller.dispose();
  }
}
