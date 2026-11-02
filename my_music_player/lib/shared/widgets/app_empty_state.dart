import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.08),
                    blurRadius: 30,
                    spreadRadius: 10)
              ],
            ),
            child: Icon(icon,
                size: 64, color: AppColors.textTertiary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const AppErrorState({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.statusError),
        const SizedBox(height: AppSpacing.md),
        Text(error,
            style: const TextStyle(color: AppColors.statusError),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full))),
            child: const Text('Retry', style: TextStyle(color: Colors.black))),
      ]),
    );
  }
}
