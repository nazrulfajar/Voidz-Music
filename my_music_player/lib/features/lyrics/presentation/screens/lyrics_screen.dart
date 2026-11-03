import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/glass_background.dart';
import '../widgets/lyrics_view.dart';

/// Full-screen lyrics surface (`docs/PRD.md` F4.5, DS §7.3).
///
/// Root route `/lyrics`; the app chrome host treats it as immersive, so
/// neither the mini player nor the tab navigation is rendered here.
class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() > 250) {
                _close(context);
              }
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: l10n.commonBack,
                        filled: false,
                        onPressed: () => _close(context),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: LyricsView()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
