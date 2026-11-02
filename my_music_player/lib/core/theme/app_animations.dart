import 'package:flutter/material.dart';

class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  // Curves
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve smoothCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.easeOutBack;
  
  // Hero Tags
  static String heroArtwork(String id) => 'artwork_$id';
}
