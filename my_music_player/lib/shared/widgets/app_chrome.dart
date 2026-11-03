import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_glass.dart';
import 'app_bottom_nav.dart';
import 'app_chrome_insets.dart';
import 'glass_background.dart';

/// Chrome class for one location.
///
/// `tabRoot` owns the navigation chrome (pill or rail) plus the mini player.
/// `detail` keeps only the mini player. `immersive` is full-bleed playback
/// surface: no chrome at all.
enum AppChromeMode { tabRoot, detail, immersive }

const _tabRootPaths = {'/', '/search', '/library'};
const _immersivePaths = {'/player', '/lyrics', '/queue'};

AppChromeMode appChromeModeFor(String location) {
  final path = location.isEmpty ? '/' : location;
  if (_immersivePaths.contains(path)) return AppChromeMode.immersive;
  if (_tabRootPaths.contains(path)) return AppChromeMode.tabRoot;
  return AppChromeMode.detail;
}

/// Single owner of the persistent mini player and navigation chrome.
///
/// Lives above the router navigator (see `VoidzApp`), so the chrome survives
/// every route: root tabs, detail pages, settings, and canonical deep links.
/// Immersive routes (player, lyrics, queue) hide it. The host measures its
/// own height and publishes it through [AppChromeInsets]; screens never
/// hardcode a mini-player/navigation reservation.
class AppChrome extends StatefulWidget {
  const AppChrome({
    super.key,
    required this.router,
    required this.child,
    this.miniPlayer,
    this.glassQuality = GlassQuality.blurred,
  });

  final GoRouter router;

  /// The router's navigator, supplied by `MaterialApp.router.builder`.
  final Widget child;

  /// Mini-player owned by the composition root. `null` when nothing plays.
  final Widget? miniPlayer;

  /// Glass quality for the floating chrome.
  final GlassQuality glassQuality;

  @override
  State<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends State<AppChrome> {
  static const _tabPaths = ['/', '/search', '/library'];

  final GlobalKey _chromeKey = GlobalKey(debugLabel: 'app-chrome');
  late String _location;
  double _bottomInset = 0;

  @override
  void initState() {
    super.initState();
    _location = _currentPath;
    widget.router.routerDelegate.addListener(_handleRouteChange);
  }

  @override
  void didUpdateWidget(AppChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_handleRouteChange);
      _location = _currentPath;
      widget.router.routerDelegate.addListener(_handleRouteChange);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_handleRouteChange);
    super.dispose();
  }

  String get _currentPath {
    final configuration = widget.router.routerDelegate.currentConfiguration;
    if (configuration.matches.isEmpty) return '/';
    // `push` keeps the location URI at the base route, so the top match is
    // the only reliable source for the visible surface.
    final path = configuration.last.matchedLocation;
    return path.isEmpty ? '/' : path;
  }

  void _handleRouteChange() {
    final next = _currentPath;
    if (next == _location) return;
    _location = next;
    // The router can notify while the first frame is still building (initial
    // route/deep link). Defer the rebuild to the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _measureChrome() {
    if (!mounted) return;
    final height = _chromeKey.currentContext?.size?.height ?? 0;
    if (height != _bottomInset) {
      setState(() => _bottomInset = height);
    }
  }

  void _onTabSelected(int index) {
    widget.router.go(_tabPaths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final mode = appChromeModeFor(_location);
    final useRail =
        MediaQuery.sizeOf(context).width >= AppShellLayout.railBreakpoint;
    final showMini =
        mode != AppChromeMode.immersive && widget.miniPlayer != null;
    final showNav = mode == AppChromeMode.tabRoot;
    final showRail = showNav && useRail;
    final showBottomBar =
        mode != AppChromeMode.immersive && (showMini || (showNav && !useRail));
    // Settings and immersive playback surfaces paint their own background.
    final showBackground =
        mode != AppChromeMode.immersive && _location != '/settings';

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChrome());

    final content = InheritedGoRouter(
      goRouter: widget.router,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppChromeInsets(
          bottom: _bottomInset,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: showRail
                        ? AppShellLayout.railContentInsetFor(context)
                        : 0,
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: showBottomBar,
                    child: widget.child,
                  ),
                ),
              ),
              if (showRail)
                Positioned(
                  left: AppShellLayout.railSideInset,
                  top: MediaQuery.paddingOf(context).top +
                      AppShellLayout.shellGap,
                  child: AppNavigationRail(
                    currentIndex: _currentTabIndex,
                    onSelected: _onTabSelected,
                    quality: widget.glassQuality,
                  ),
                ),
              if (showBottomBar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    key: _chromeKey,
                    top: false,
                    minimum: const EdgeInsets.only(
                      bottom: AppShellLayout.shellGap,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: showRail
                            ? AppShellLayout.railContentInsetFor(context)
                            : 0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showMini) widget.miniPlayer!,
                          if (showNav && !useRail)
                            AppBottomNav(
                              currentIndex: _currentTabIndex,
                              onSelected: _onTabSelected,
                              quality: widget.glassQuality,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showBackground) return content;
    return GlassBackground(child: content);
  }

  int get _currentTabIndex {
    final index = _tabPaths.indexOf(_location);
    return index < 0 ? 0 : index;
  }
}
