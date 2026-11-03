/// Largest artwork width the app ever requests or stores.
///
/// Matches the decode cap used by `AppArtwork`, so cached files never exceed
/// what the UI can render.
const int maxCachedArtworkWidth = 1024;

/// Returns [url] resized to [width] when it is a square YouTube thumbnail.
///
/// Only `https://yt3.googleusercontent.com` URLs without user info/extra port
/// and with a single square `=wN-hN-l90-rj` suffix are rewritten. Anything
/// else — including sources that are already at least [width] wide or that
/// carry conflicting size options — is returned unchanged.
String youtubeArtworkUrl(String url, int width) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'yt3.googleusercontent.com' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) {
    return url;
  }

  final match = RegExp(r'=w(\d+)-h(\d+)-l90-rj$').firstMatch(uri.path);
  if (match == null) return url;
  final sourceWidth = int.tryParse(match.group(1)!);
  final sourceHeight = int.tryParse(match.group(2)!);
  if (sourceWidth == null ||
      sourceWidth <= 0 ||
      sourceWidth != sourceHeight ||
      sourceWidth >= width) {
    return url;
  }

  final path = uri.path.replaceRange(
    match.start,
    match.end,
    '=w$width-h$width-l90-rj',
  );
  return uri.replace(path: path).toString();
}
