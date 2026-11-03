/// Maximum bytes per upstream range request to googlevideo.
///
/// YouTube's `androidSdkless` stream URLs currently return HTTP 403 for
/// open-ended ranges (`bytes=0-`), requests without a range, and ranges
/// larger than roughly 1 MB. 256 KiB also stays below the stricter limit
/// used by low-bitrate audio streams.
const int maxStreamRangeBytes = 256 * 1024;

/// Returns a bounded `Range` header for a googlevideo stream request.
///
/// Falls back to the first bounded chunk when [raw] is missing or malformed.
/// Open-ended ranges are capped at [maxBytes]; already-small ranges are kept.
String buildBoundedRange(
  String? raw, {
  int maxBytes = maxStreamRangeBytes,
}) {
  assert(maxBytes > 0, 'maxBytes must be positive');
  final fallback = 'bytes=0-${maxBytes - 1}';
  if (raw == null || raw.trim().isEmpty) return fallback;

  final header = raw.trim().toLowerCase();
  if (!header.startsWith('bytes=')) return fallback;

  // A multi-range request is unusual for ExoPlayer; use the first one.
  final spec = header.substring('bytes='.length).split(',').first.trim();
  final match = RegExp(r'^(\d*)-(\d*)$').firstMatch(spec);
  if (match == null) return fallback;

  final startRaw = match.group(1)!;
  final endRaw = match.group(2)!;
  if (startRaw.isEmpty && endRaw.isEmpty) return fallback;

  // Suffix range (`bytes=-500`) starts at zero in our bounded model.
  if (startRaw.isEmpty) {
    final suffix = int.tryParse(endRaw);
    if (suffix == null || suffix <= 0) return fallback;
    final length = suffix > maxBytes ? maxBytes : suffix;
    return 'bytes=0-${length - 1}';
  }

  final start = int.tryParse(startRaw);
  if (start == null || start < 0) return fallback;

  final requestedEnd = endRaw.isEmpty ? null : int.tryParse(endRaw);
  if (requestedEnd != null && requestedEnd < start) return fallback;

  final maxEnd = start + maxBytes - 1;
  final end = requestedEnd == null
      ? maxEnd
      : (requestedEnd > maxEnd ? maxEnd : requestedEnd);
  return 'bytes=$start-$end';
}

/// Returns the first byte requested by a bounded `Range` header.
int rangeStart(String range) {
  final spec = range.startsWith('bytes=') ? range.substring(6) : range;
  final start = spec.split('-').first;
  return int.tryParse(start) ?? 0;
}
