import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/sleep_timer_provider.dart';

void showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => const SleepTimerSheet(),
  );
}

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60);
      return '${d.inHours}h ${m > 0 ? '${m}m' : ''}';
    }
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timerState = ref.watch(sleepTimerProvider);

    final options = [
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(minutes: 60),
    ];

    return Material(
      color: AppColors.surfaceBase,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOverlay,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Text(
              'Sleep Timer',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Stop audio playback after a set amount of time.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (timerState.isActive) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.accentPrimary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timer Active',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.accentPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${timerState.remainingTime.inMinutes}:${(timerState.remainingTime.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(sleepTimerProvider.notifier).stopTimer();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.accentPrimary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            Expanded(
              flex: 0,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final duration = options[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time,
                        color: AppColors.textSecondary),
                    title: Text(_formatDuration(duration)),
                    onTap: () {
                      ref
                          .read(sleepTimerProvider.notifier)
                          .startTimer(duration);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl), // Safe area spacing
          ],
        ),
      ),
    );
  }
}
