import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const AppFilterChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.4),
        selectedColor: AppColors.textPrimary,
        labelStyle: TextStyle(
            color: selected ? AppColors.surfaceBase : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            side: BorderSide(
                color: selected ? Colors.transparent : Colors.white24)),
      ),
    );
  }
}
