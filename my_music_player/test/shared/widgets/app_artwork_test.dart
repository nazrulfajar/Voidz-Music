import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/shared/widgets/app_artwork.dart';

import '../../helpers/pump_app.dart';

const _youtubeUrl =
    'https://yt3.googleusercontent.com/cover=w120-h120-l90-rj?source=test';

class _ControlledImageStream extends ImageStreamCompleter {
  void show(ui.Image image) => setImage(ImageInfo(image: image));

  void fail() => reportError(exception: Exception('offline'), silent: true);
}

Future<void> _pumpArtwork(
  WidgetTester tester, {
  String? imageUrl = _youtubeUrl,
  String? localPath,
  double size = 312,
  double pixelRatio = 3,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: Center(
        child: MediaQuery(
          data: MediaQueryData(devicePixelRatio: pixelRatio),
          child: AppArtwork(
            imageUrl: imageUrl,
            localPath: localPath,
            size: size,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('requests YouTube artwork at the physical display size',
      (tester) async {
    await _pumpArtwork(tester);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage).last,
    );
    expect(
      image.imageUrl,
      'https://yt3.googleusercontent.com/'
      'cover=w936-h936-l90-rj?source=test',
    );
    expect(image.memCacheWidth, 936);
  });

  testWidgets('caps large requests and decodes to the capped size',
      (tester) async {
    await _pumpArtwork(tester, size: 400, pixelRatio: 4);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage).last,
    );
    expect(image.imageUrl, contains('=w1024-h1024-l90-rj'));
    expect(image.memCacheWidth, 1024);
  });

  testWidgets('keeps the original visible if the larger request fails',
      (tester) async {
    await _pumpArtwork(tester);

    final finder = find.byType(CachedNetworkImage);
    final originalImage = tester.widget<CachedNetworkImage>(finder.first);
    final image = tester.widget<CachedNetworkImage>(finder.last);
    final context = tester.element(finder.last);
    expect(originalImage.imageUrl, _youtubeUrl);
    expect(
      image.errorWidget!(context, image.imageUrl, Exception()),
      isA<SizedBox>(),
    );
    expect(
      originalImage.errorWidget!(context, _youtubeUrl, Exception()),
      isA<DecoratedBox>(),
    );
  });

  testWidgets('renders cached artwork when the resized image fails',
      (tester) async {
    const path = 'ios/Runner/Assets.xcassets/'
        'AppIcon.appiconset/Icon-App-60x60@2x.png';
    final frame = await tester.runAsync(() async {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      return codec.getNextFrame();
    });
    const original = ResizeImage(
      CachedNetworkImageProvider(_youtubeUrl),
      width: 936,
    );
    const resized = ResizeImage(
      CachedNetworkImageProvider(
        'https://yt3.googleusercontent.com/'
        'cover=w936-h936-l90-rj?source=test',
      ),
      width: 936,
    );
    final originalKey = await original.obtainKey(ImageConfiguration.empty);
    final resizedKey = await resized.obtainKey(ImageConfiguration.empty);
    final cache = PaintingBinding.instance.imageCache;
    cache.evict(originalKey);
    cache.evict(resizedKey);
    final originalStream = _ControlledImageStream()..show(frame!.image);
    final resizedStream = _ControlledImageStream();
    cache.putIfAbsent(originalKey, () => originalStream);
    cache.putIfAbsent(resizedKey, () => resizedStream);
    addTearDown(() {
      cache.evict(originalKey);
      cache.evict(resizedKey);
    });

    await _pumpArtwork(tester);
    expect(resizedStream.hasListeners, isTrue);
    resizedStream.fail();
    await tester.pumpAndSettle();

    final originalFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CachedNetworkImage && widget.imageUrl == _youtubeUrl,
    );
    final rendered = find.descendant(
      of: originalFinder,
      matching: find.byType(RawImage),
    );
    expect(tester.widget<RawImage>(rendered).image, isNotNull);
  });

  testWidgets('keeps an image that is already large enough', (tester) async {
    const url = 'https://yt3.googleusercontent.com/cover=w1000-h1000-l90-rj';
    await _pumpArtwork(tester, imageUrl: url);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, url);
  });

  testWidgets('leaves unsupported URLs and non-square sizes unchanged',
      (tester) async {
    const urls = [
      'https://example.com/cover=w120-h120-l90-rj',
      'https://yt3.googleusercontent.com.evil.example/cover=w120-h120-l90-rj',
      'http://yt3.googleusercontent.com/cover=w120-h120-l90-rj',
      'https://yt3.googleusercontent.com/cover=w120-h90-l90-rj',
      'https://yt3.googleusercontent.com/cover?size=w120-h120-l90-rj',
    ];
    for (final url in urls) {
      await _pumpArtwork(tester, imageUrl: url);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, url);
    }
  });

  testWidgets('keeps a cached local artwork ahead of the network URL',
      (tester) async {
    const path = 'ios/Runner/Assets.xcassets/'
        'AppIcon.appiconset/Icon-App-60x60@2x.png';
    await pumpApp(tester, const Scaffold());
    await tester.runAsync(() async {
      await precacheImage(
        ResizeImage(FileImage(File(path)), width: 936),
        tester.element(find.byType(Scaffold)),
      );
    });
    await _pumpArtwork(tester, localPath: path);

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });

  testWidgets('keeps the original cache URL across different display sizes',
      (tester) async {
    await _pumpArtwork(tester, size: 48);
    expect(
      tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((image) => image.imageUrl),
      containsAll([_youtubeUrl, contains('=w144-h144-l90-rj')]),
    );

    await _pumpArtwork(tester, size: 44);
    expect(
      tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((image) => image.imageUrl),
      containsAll([_youtubeUrl, contains('=w132-h132-l90-rj')]),
    );
  });

  testWidgets('does not resize a URL with conflicting size options',
      (tester) async {
    const url = 'https://yt3.googleusercontent.com/'
        'cover=w120-h120-w2048-h2048-l90-rj';
    await _pumpArtwork(tester, imageUrl: url);
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, url);
  });

  testWidgets('preserves the original decode width for other hosts',
      (tester) async {
    const url = 'https://example.com/landscape.jpg';
    await _pumpArtwork(tester, imageUrl: url, pixelRatio: 2);
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 936);
  });
}
