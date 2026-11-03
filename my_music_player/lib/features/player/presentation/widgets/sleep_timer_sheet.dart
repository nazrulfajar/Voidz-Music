import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_surface.dart';
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

  String _formatDuration(AppLocalizations l10n, Duration d) =>
      l10n.sleepTimerMinutes(d.inMinutes);

  String _formatRemaining(AppLocalizations l10n, Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return l10n.sleepTimerRemaining(
      '$minutes:${seconds.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(sleepTimerProvider);

    return GlassSurface.chrome(
      key: const Key('sleep-timer-sheet-glass'),
      // Stable chrome panel; option rows stay on the panel without their own
      // blur, so the sheet adds zero BackdropFilter layers.
      quality: GlassQuality.frosted,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: Material(
        color: Colors.transparent,
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
                  l10n.sleepTimerTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.sleepTimerSubtitle,
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
                                    ? l10n.sleepTimerEndOfTrack
                                    : l10n.sleepTimerActive,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timerState.isEndOfTrack
                                    ? l10n.sleepTimerSubtitle
                                    : _formatRemaining(
                                        l10n,
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
                            l10n.commonCancelAction,
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
                    label: _formatDuration(l10n, duration),
                    selected: timerState.isActive &&
                        timerState.mode == SleepTimerMode.duration &&
                        timerState.selectedDuration == duration,
                    onTap: () {
                      ref
                          .read(sleepTimerProvider.notifier)
                          .startTimer(duration);
                      Navigator.pop(context);
                    },
                  ),
                const Divider(height: 1),
                _OptionTile(
                  icon: Icons.music_note_outlined,
                  label: l10n.sleepTimerEndOfTrack,
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
    final l10n = AppLocalizations.of(context);
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
          semanticLabel: selected ? l10n.commonSelected : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
