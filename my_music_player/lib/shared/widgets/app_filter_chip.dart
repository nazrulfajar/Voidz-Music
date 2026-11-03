import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: t.surface,
        selectedColor: t.accent,
        labelStyle: TextStyle(
          color: selected ? t.onAccent : t.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
        side: BorderSide(color: selected ? t.accent : t.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
