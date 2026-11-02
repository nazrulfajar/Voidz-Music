import 'package:flutter/material.dart';

class AppColors {
  // Base Surface Colors (Black / Dark Gray Mode)
  static const Color surfaceBase = Color(0xFF09090B); // Zinc 950 (Black)
  static const Color surfaceElevated = Color(0xFF18181B); // Zinc 900
  static const Color surfaceOverlay = Color(0xFF27272A); // Zinc 800
  static const Color surfaceHover = Color(0xFF3F3F46); // Zinc 700

  // Accent Colors (Sky Blue & Premium additions)
  static const Color accentPrimary = Color(0xFF38BDF8); // Sky 400
  static const Color accentPrimaryVariant = Color(0xFF0284C7); // Sky 600
  static const Color accentSecondary = Color(0xFF7DD3FC); // Sky 300
  static const Color accentTertiary = Color(0xFFBAE6FD); // Sky 200
  
  // Premium Gradients & Glows
  static const Color glowColor = Color(0x3338BDF8); // Soft sky glow
  static const Color blurBackground = Color(0x8009090B); // 50% opacity base for glassmorphism
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white for glass borders

  // Text Colors (White / Gray)
  static const Color textPrimary = Color(0xFFFAFAFA); // Zinc 50 (White)
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400 (Gray)
  static const Color textTertiary = Color(0xFF71717A); // Zinc 500 (Darker Gray)
  static const Color textOnAccent = Color(0xFF0F172A); // Slate 900 (Dark text on sky blue)

  // Semantic Colors
  static const Color statusSuccess = Color(0xFF4ADE80);
  static const Color statusWarning = Color(0xFFFACC15);
  static const Color statusError = Color(0xFFF87171);
  static const Color statusInfo = Color(0xFF38BDF8);

  // Transparent / Utility
  static const Color transparent = Colors.transparent;
}
