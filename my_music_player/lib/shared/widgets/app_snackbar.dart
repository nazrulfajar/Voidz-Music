import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(context, message);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message);
  }

  /// Snackbars are monochrome: `raised` surface with `textPrimary` copy and a
  /// 1px border (`docs/DESIGN_SYSTEM.md` §6.7).
  static void _show(BuildContext context, String message) {
    final tokens = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 13, color: tokens.textPrimary),
        ),
        backgroundColor: tokens.raised,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: tokens.border),
        ),
      ),
    );
  }
}
