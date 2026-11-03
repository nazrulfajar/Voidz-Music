/// Shared component metrics from `docs/DESIGN_SYSTEM.md` §6.4.
class AppSizes {
  const AppSizes._();

  /// Track row height at normal text scale (design: 72 dp, r18).
  ///
  /// Rows constrain with `minHeight` so larger text scales can grow the row
  /// instead of clipping the title or artist.
  static const double trackRowHeight = 72.0;
}
