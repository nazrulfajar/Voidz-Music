import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'shimmer_loading.dart';

/// Visual variant of [AppStatePanel].
enum AppStateVariant { empty, error, offline, permission, loading }

/// Shared state surface used by every screen for empty, error, offline,
/// permission and loading states.
///
/// Geometry follows `docs/DESIGN_SYSTEM.md` §6.7: panel `surface` with a 1px
/// border and r24, 72dp circle, 20 SemiBold title, 14 body and an optional
/// 48dp CTA.
class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    this.variant = AppStateVariant.empty,
    this.title = '',
    this.message,
    this.icon,
    this.code,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.actionWidget,
    this.footnote,
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  final AppStateVariant variant;
  final String title;
  final String? message;
  final IconData? icon;

  /// Small monospace-style error code, for example `ERR-NET-01`.
  final String? code;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// Legacy custom action widget. Takes precedence over [actionLabel].
  final Widget? actionWidget;
  final String? footnote;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  bool get _isLoading => variant == AppStateVariant.loading;

  IconData get _resolvedIcon {
    if (icon != null) return icon!;
    switch (variant) {
      case AppStateVariant.empty:
        return Icons.inbox_rounded;
      case AppStateVariant.error:
        return Icons.error_outline_rounded;
      case AppStateVariant.offline:
        return Icons.cloud_off_rounded;
      case AppStateVariant.permission:
        return Icons.smartphone_rounded;
      case AppStateVariant.loading:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final circleBorder =
        variant == AppStateVariant.error ? tokens.focusedBorder : tokens.border;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 412, minHeight: 440),
          child: Container(
            key: const Key('app-state-panel'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  key: const Key('app-state-panel-circle'),
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: circleBorder),
                  ),
                  child: Icon(
                    _resolvedIcon,
                    size: 33,
                    color: tokens.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: AppSpacing.space6),
                  const ShimmerBox(
                    width: 180,
                    height: 16,
                    radius: 8,
                    opacity: 0.10,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  const ShimmerBox(
                    width: 140,
                    height: 10,
                    radius: 5,
                    opacity: 0.05,
                  ),
                ] else ...[
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                  if (variant == AppStateVariant.error && code != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      code!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: tokens.textInactive,
                      ),
                    ),
                  ],
                  if (actionWidget != null) ...[
                    const SizedBox(height: AppSpacing.space6),
                    actionWidget!,
                  ] else if (actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.space6),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: Icon(
                        actionIcon ?? Icons.arrow_forward_rounded,
                        size: 15,
                      ),
                      label: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: tokens.onAccent,
                        minimumSize: const Size(148, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space5,
                          vertical: AppSpacing.space3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    TextButton(
                      onPressed: onSecondaryAction,
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.textPrimary,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                  ],
                  if (footnote != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      footnote!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return AppStatePanel(
      variant: AppStateVariant.empty,
      icon: icon,
      title: title,
      message: subtitle,
      actionWidget: action,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryLabel: secondaryLabel,
      onSecondaryAction: onSecondaryAction,
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  /// Optional explicit code. When null it is derived from [cause].
  final String? code;

  /// Optional failure/exception used only to derive the code. It is never
  /// rendered; callers must pass a human-readable [error] message.
  final Object? cause;
  final String title;
  final String retryLabel;

  const AppErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.code,
    this.cause,
    this.title = "Couldn't load results",
    this.retryLabel = 'Retry',
  });

  /// Maps a failure to the design error code (`docs/DESIGN_SYSTEM.md` §6.7).
  static String codeFor(Object? cause) {
    if (cause is NetworkFailure) return 'ERR-NET-01';
    if (cause is ResolverFailure) return 'ERR-RES-01';
    return 'ERR-APP-01';
  }

  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      variant: AppStateVariant.error,
      title: title,
      message: error,
      code: code ?? codeFor(cause),
      actionLabel: retryLabel,
      onAction: onRetry,
      actionIcon: Icons.refresh_rounded,
    );
  }
}

/// Offline banner from `docs/DESIGN_SYSTEM.md` §6.7: 380x72, r20, `raised`.
class AppOfflineBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;

  const AppOfflineBanner({
    super.key,
    this.title = "You're offline",
    this.message = 'Playing downloaded songs',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final banner = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        key: const Key('app-offline-banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: tokens.raised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: tokens.textPrimary,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return banner;
    return Semantics(
      button: true,
      label: '$title. $message',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ExcludeSemantics(child: banner),
      ),
    );
  }
}
