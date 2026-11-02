import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Legacy custom action widget. Takes precedence over [actionLabel].
  final Widget? action;

  /// Primary action label; rendered as a themed [FilledButton].
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional secondary action; rendered as a themed [TextButton].
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondaryAction,
  })  : assert(
          actionLabel == null || onAction != null,
          'onAction is required when actionLabel is set',
        ),
        assert(
          secondaryLabel == null || onSecondaryAction != null,
          'onSecondaryAction is required when secondaryLabel is set',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: tokens.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 64,
              color: tokens.textInactive.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ] else if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.space1),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: tokens.textPrimary),
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            style: TextStyle(color: tokens.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
