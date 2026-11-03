import 'package:flutter/material.dart';

/// Flat elevation system from `docs/DESIGN_SYSTEM.md` §8.
///
/// Surfaces are separated with 1px borders; shadows are reserved for floating
/// elements only.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> switchKnob = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> miniPlayer = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Glass chrome shadow, dark: `0 18 40 #00000059` (§0.2).
  static const List<BoxShadow> glassChromeDark = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
  ];

  /// Glass chrome shadow, light provisional: `0 18 40 #0A10181F` (§0.2).
  static const List<BoxShadow> glassChromeLight = [
    BoxShadow(
      color: Color(0x1F0A1018),
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> sliderThumb = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
