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

  static const _options = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  String _formatDuration(Duration d) => '${d.inMinutes} minutes';

  String _formatRemaining(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')} remaining';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final timerState = ref.watch(sleepTimerProvider);

    return Material(
      color: t.panel,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                    color: t.textPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              Text(
                'Sleep timer',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Playback stops automatically',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (timerState.isActive) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: t.raised,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: t.textPrimary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timerState.isEndOfTrack
                                  ? 'End of track'
                                  : 'Timer Active',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              timerState.isEndOfTrack
                                  ? 'Playback stops automatically'
                                  : _formatRemaining(
                                      timerState.remainingTime,
                                    ),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: t.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(sleepTimerProvider.notifier).stopTimer();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final duration in _options)
                _OptionTile(
                  icon: Icons.access_time,
                  label: _formatDuration(duration),
                  selected: timerState.isActive &&
                      timerState.mode == SleepTimerMode.duration &&
                      timerState.selectedDuration == duration,
                  onTap: () {
                    ref.read(sleepTimerProvider.notifier).startTimer(duration);
                    Navigator.pop(context);
                  },
                ),
              const Divider(height: 1),
              _OptionTile(
                icon: Icons.music_note_outlined,
                label: 'End of track',
                selected: timerState.isEndOfTrack,
                onTap: () {
                  ref.read(sleepTimerProvider.notifier).startEndOfTrack();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return Semantics(
      selected: selected,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: t.textSecondary),
        title: Text(
          label,
          style: TextStyle(color: t.textPrimary),
        ),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? t.textPrimary : t.textMuted,
          semanticLabel: selected ? 'Selected' : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
