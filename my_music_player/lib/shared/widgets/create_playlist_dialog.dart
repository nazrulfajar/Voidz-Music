import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          backgroundColor: tokens.row,
          title: Text(
            l10n.playlistNewTitle,
            style: TextStyle(color: tokens.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: tokens.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.playlistNameHint,
              hintStyle: TextStyle(color: tokens.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.commonCancelAction,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final n = controller.text.trim();
                if (n.isNotEmpty) Navigator.pop(dialogContext, n);
              },
              child: Text(
                l10n.playlistCreate,
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
  final l10n = AppLocalizations.of(context);
  try {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final dialogTokens = AppColors.of(dialogContext);
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          backgroundColor: dialogTokens.row,
          title: Text(
            dialogL10n.playlistNewTitle,
            style: TextStyle(color: dialogTokens.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: dialogTokens.textPrimary),
            decoration: InputDecoration(
              hintText: dialogL10n.playlistNameHint,
              hintStyle: TextStyle(color: dialogTokens.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                dialogL10n.commonCancelAction,
                style: TextStyle(color: dialogTokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final n = controller.text.trim();
                if (n.isNotEmpty) Navigator.pop(dialogContext, n);
              },
              child: Text(
                dialogL10n.playlistCreateAndAdd,
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
      final String msg;
      if (res.added == 0) {
        msg = l10n.playlistAlreadyIn(playlist.name);
      } else if (tracks.length == 1) {
        msg = l10n.playlistAddedTo(playlist.name);
      } else {
        final suffix = res.existed > 0
            ? ' ${l10n.playlistAlreadyExisted(res.existed)}'
            : '';
        msg = '${l10n.playlistAddedMany(res.added, playlist.name)}$suffix';
      }
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
