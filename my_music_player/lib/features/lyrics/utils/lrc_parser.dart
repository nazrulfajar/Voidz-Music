import '../domain/entities/lrc_line.dart';

class ParsedLyrics {
  final List<LrcLine> lines;

  ParsedLyrics(this.lines);

  /// Returns the index of the active line for the given position.
  /// If position is before the first line, returns -1.
  int getActiveLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    if (position < lines.first.time) return -1;

    for (int i = 0; i < lines.length; i++) {
      if (i == lines.length - 1) {
        return i; // Last line
      }
      if (position >= lines[i].time && position < lines[i + 1].time) {
        return i;
      }
    }
    return -1;
  }
}

class LrcParser {
  static ParsedLyrics parse(String lrcContent) {
    final List<LrcLine> lines = [];
    // Matches tags like [01:23.45] or [01:23:45] or [01:23.456]
    final RegExp timePattern = RegExp(r'\[(\d{2}):(\d{2})[.:](\d{2,3})\]');

    final rawLines = lrcContent.split(RegExp(r'\r?\n'));
    for (final rawLine in rawLines) {
      final matches = timePattern.allMatches(rawLine);
      if (matches.isEmpty) continue;

      // The text is the remaining part of the string after removing all time tags
      String text = rawLine.replaceAll(timePattern, '').trim();

      // Some LRC files have multiple time tags for the same text line
      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        
        // Handle hundredths or milliseconds
        String msStr = match.group(3) ?? '0';
        int milliseconds = 0;
        if (msStr.length == 2) {
          milliseconds = (int.tryParse(msStr) ?? 0) * 10;
        } else if (msStr.length == 3) {
          milliseconds = int.tryParse(msStr) ?? 0;
        }

        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lines.add(LrcLine(time: time, text: text));
      }
    }

    // Sort by time in case multiple time tags were out of order
    lines.sort((a, b) => a.time.compareTo(b.time));
    return ParsedLyrics(lines);
  }
}
