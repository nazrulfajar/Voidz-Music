import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/player/presentation/widgets/mini_player.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/app_artwork.dart';
import 'package:my_music_player/shared/widgets/app_icon_button.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

const _controlLabels = <String>[
  'Close player',
  'More options',
  'Like',
  'Shuffle',
  'Previous',
  'Play',
  'Next',
  'Repeat',
];

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'The Weeknd',
    album: 'Starboy',
    durationMs: 230000,
    source: TrackSource.youtube,
    audioFormat: 'AAC',
    bitrateKbps: 320,
  );
}

PlayerState _playerState({
  bool isLiked = false,
  bool isPlaying = false,
  int queueLength = 2,
}) {
  final queue = List<Track>.generate(queueLength, (index) => _track('v$index'));
  return PlayerState(
    currentTrack: queue.first.copyWith(isLiked: isLiked),
    currentQueue: queue,
    currentIndex: 0,
    isPlaying: isPlaying,
    position: const Duration(seconds: 102),
    duration: const Duration(seconds: 230),
  );
}

/// Keeps the real [PlayerController] wiring out of the widget test while
/// exposing the same provider type.
class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref, PlayerState initial)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = initial;
  }
}

Widget _playerApp(PlayerState state) => _app(state, const PlayerScreen());

Widget _miniPlayerApp(PlayerState state) => _app(state, const MiniPlayer());

Widget _app(PlayerState state, Widget child) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(ref, state),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('player controls have labels and >= 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(tester, _playerApp(_playerState()));

      for (final label in _controlLabels) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }

      for (final element in find.byType(AppIconButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('unavailable shuffle is announced as disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(tester, _playerApp(_playerState(queueLength: 1)));

      final node = tester.getSemantics(find.bySemanticsLabel('Shuffle'));
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('player handles textScale 2.0 without overflow', (tester) async {
    await pumpApp(
      tester,
      _playerApp(_playerState()),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text('Track v0')).maxLines, 1);

    for (final label in const ['Lyrics', 'Queue (2)', 'Timer']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      final size = tester.getSize(find.bySemanticsLabel(label));
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
    }
  });

  testWidgets('player renders controls with light theme tokens',
      (tester) async {
    await pumpApp(
      tester,
      _playerApp(_playerState()),
      themeMode: ThemeMode.light,
    );

    final likeIcon = tester.widget<Icon>(
      find.descendant(
        of: find.bySemanticsLabel('Like'),
        matching: find.byType(Icon),
      ),
    );
    expect(likeIcon.color, AppColors.light.textPrimary);

    final playIcon = tester.widget<Icon>(
      find.descendant(
        of: find.bySemanticsLabel('Play'),
        matching: find.byType(Icon),
      ),
    );
    expect(playIcon.color, AppColors.light.onAccent);

    expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);
    expect(find.bySemanticsLabel('Repeat'), findsOneWidget);
  });

  testWidgets('more menu exposes player actions', (tester) async {
    await pumpApp(tester, _playerApp(_playerState()));

    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Sleep Timer'), findsOneWidget);
    expect(find.text('Add to Playlist'), findsOneWidget);
    expect(find.text('Starboy'), findsOneWidget);
  });

  testWidgets('mini player controls have labels and >= 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(tester, _miniPlayerApp(_playerState(isPlaying: true)));

      for (final label in const ['Previous', 'Pause', 'Next']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('mini player handles textScale 2.0 without overflow',
      (tester) async {
    await pumpApp(
      tester,
      _miniPlayerApp(_playerState()),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('mini player matches cover, text and progress reference padding',
      (tester) async {
    await pumpApp(tester, _miniPlayerApp(_playerState()));

    final surface = tester.getRect(find.byType(GlassSurface));
    final artwork = tester.getRect(find.byType(AppArtwork));
    final title = tester.getRect(find.text('Track v0'));
    expect(surface.height, 66);
    expect(artwork.size, const Size(46, 46));
    expect(artwork.top - surface.top, 10);
    expect(surface.bottom - artwork.bottom, 10);
    expect(title.left - artwork.right, 12);

    final artist = tester.widget<Text>(find.text('The Weeknd · youtube'));
    expect(artist.maxLines, 1);
    expect(artist.overflow, TextOverflow.ellipsis);
    final progress = tester.getRect(find.bySemanticsLabel('Playback position'));
    expect(progress.left - surface.left, 16);
    expect(surface.right - progress.right, 16);
    expect(surface.bottom - progress.bottom, 2);
    expect(tester.takeException(), isNull);
  });
}
