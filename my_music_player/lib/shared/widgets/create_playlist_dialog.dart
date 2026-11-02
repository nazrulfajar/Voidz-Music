import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/library/data/repositories/playlist_repository_impl.dart';
import '../../features/library/presentation/providers/playlist_provider.dart';

/// Single reusable dialog — tidak duplikat di library_screen & add_to_playlist_sheet
Future<String?> showCreatePlaylistDialog(
    BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  try {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final tokens = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: tokens.row,
          title: Text(
            'New Playlist',
            style: TextStyle(color: tokens.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: tokens.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: tokens.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final n = controller.text.trim();
                if (n.isNotEmpty) Navigator.pop(dialogContext, n);
              },
              child: Text(
                'Create',
                style: TextStyle(color: tokens.accent),
              ),
            ),
          ],
        );
      },
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(playlistRepositoryProvider).createPlaylist(name.trim());
      ref.invalidate(allPlaylistsProvider);
      return name.trim();
    }
    return null;
  } finally {
    // The dialog route still rebuilds its TextField during the reverse
    // transition; dispose only after that animation completed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }
}

/// Khusus add_to_playlist: create + add batch — tidak leak controller
Future<void> showCreateAndAddDialog(
  BuildContext context,
  WidgetRef ref,
  List<dynamic> tracks,
) async {
  final controller = TextEditingController();
  final tokens = AppColors.of(context);
  try {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final dialogTokens = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: dialogTokens.row,
          title: Text(
            'New Playlist',
            style: TextStyle(color: dialogTokens.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: dialogTokens.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: dialogTokens.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: dialogTokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final n = controller.text.trim();
                if (n.isNotEmpty) Navigator.pop(dialogContext, n);
              },
              child: Text(
                'Create & Add',
                style: TextStyle(color: dialogTokens.accent),
              ),
            ),
          ],
        );
      },
    );
    if (name == null || name.trim().isEmpty) return;
    final playlist =
        await ref.read(playlistRepositoryProvider).createPlaylist(name.trim());
    final res = await ref
        .read(playlistRepositoryProvider)
        .addTracksToPlaylist(playlist.id!, tracks.cast());
    ref.invalidate(allPlaylistsProvider);
    if (context.mounted) {
      Navigator.pop(context); // close bottom sheet
      final msg = res.added > 0
          ? (tracks.length == 1
              ? 'Added to ${playlist.name}'
              : 'Added ${res.added} tracks to ${playlist.name}'
                  '${res.existed > 0 ? ' (${res.existed} already existed)' : ''}')
          : 'Already in ${playlist.name}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: TextStyle(color: tokens.textPrimary),
          ),
          backgroundColor: tokens.raised,
        ),
      );
    }
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }
}
