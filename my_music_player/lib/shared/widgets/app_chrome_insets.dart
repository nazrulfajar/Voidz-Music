import 'package:flutter/widgets.dart';

/// Bottom inset owned by the app-level chrome host.
///
/// Screens append [bottomOf] to scroll padding instead of hardcoding a
/// mini-player/navigation reservation. The host measures its own chrome
/// (safe area included), so the value stays correct on any viewport, text
/// scale, and route class.
class AppChromeInsets extends InheritedWidget {
  const AppChromeInsets({
    super.key,
    required this.bottom,
    required super.child,
  });

  /// Height of the visible floating chrome, in logical pixels.
  final double bottom;

  static double bottomOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppChromeInsets>()
            ?.bottom ??
        0;
  }

  /// Inset for scrollables that do not sit inside a bottom [SafeArea].
  ///
  /// When chrome is visible the host already removed the MediaQuery bottom
  /// padding, so the measured chrome wins. Without chrome the system gesture
  /// inset is the floor.
  static double scrollBottomOf(BuildContext context) {
    final chrome = bottomOf(context);
    final safe = MediaQuery.paddingOf(context).bottom;
    return chrome > safe ? chrome : safe;
  }

  @override
  bool updateShouldNotify(AppChromeInsets oldWidget) {
    return oldWidget.bottom != bottom;
  }
}

/// Sliver spacer that keeps the last row scrollable above the app chrome.
class ChromeBottomSliver extends StatelessWidget {
  const ChromeBottomSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: AppChromeInsets.scrollBottomOf(context)),
    );
  }
}
