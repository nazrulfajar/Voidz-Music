import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/enums.dart';
import '../providers/settings_provider.dart';
import '../../../cache/presentation/providers/cache_stats_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final settingsAsync = ref.watch(appSettingsProvider);
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final controller = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final cacheMb = settings.maxCacheSizeBytes / (1024 * 1024);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSectionTitle(tokens, 'Sources'),
              _buildCard(
                tokens,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Enable YouTube Source',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      activeTrackColor: tokens.accent,
                      activeThumbColor: tokens.onAccent,
                      value: settings.enableYoutubeSource,
                      onChanged: (val) => controller.toggleYoutubeSource(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(tokens, 'Audio'),
              _buildCard(
                tokens,
                child: ListTile(
                  title: Text(
                    'Preferred Audio Quality',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                  trailing: Semantics(
                    label: 'Preferred Audio Quality',
                    child: DropdownButton<AudioQuality>(
                      dropdownColor: tokens.raised,
                      value: settings.preferredAudioQuality,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: tokens.textPrimary),
                      icon: Icon(Icons.arrow_drop_down,
                          color: tokens.textPrimary),
                      underline: const SizedBox(),
                      onChanged: (AudioQuality? newValue) {
                        if (newValue != null) {
                          controller.setAudioQuality(newValue);
                        }
                      },
                      items: AudioQuality.values
                          .map<DropdownMenuItem<AudioQuality>>(
                              (AudioQuality value) {
                        return DropdownMenuItem<AudioQuality>(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(tokens, 'Cache'),
              _buildCard(
                tokens,
                child: Column(
                  children: [
                    cacheStatsAsync.when(
                      data: (stats) {
                        final usedMb =
                            stats.totalCacheSizeBytes / (1024 * 1024);
                        final maxMb = stats.maxCacheSizeBytes / (1024 * 1024);
                        final pct =
                            (stats.usagePercentage * 100).toStringAsFixed(0);
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                'Storage Used',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: tokens.textPrimary),
                              ),
                              subtitle: Text(
                                '${usedMb.toStringAsFixed(1)} MB / ${maxMb.toInt()} MB ($pct%) • ${stats.totalCachedTracks} tracks${stats.pinnedTrackIds.isNotEmpty ? ' • ${stats.pinnedTrackIds.length} pinned' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: stats.isNearLimit
                                      ? tokens.textPrimary
                                      : tokens.textSecondary,
                                ),
                              ),
                            ),
                            LinearProgressIndicator(
                              value: stats.usagePercentage.clamp(0.0, 1.0),
                              backgroundColor: tokens.track,
                              color: tokens.accent,
                              minHeight: 6,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    ListTile(
                      title: Text(
                        'Max Cache Size',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      subtitle: Text(
                        '${cacheMb.toInt()} MB',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                    Semantics(
                      label: 'Max Cache Size',
                      child: SizedBox(
                        height: 48,
                        child: Slider(
                          activeColor: tokens.accent,
                          inactiveColor: tokens.track,
                          value: cacheMb.clamp(250, 10000),
                          min: 250,
                          max: 10000,
                          divisions: 39,
                          label: '${cacheMb.toInt()} MB',
                          onChanged: (val) {
                            controller.setCacheLimitMb(val.toInt());
                          },
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Auto-Cache on Play',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      activeTrackColor: tokens.accent,
                      activeThumbColor: tokens.onAccent,
                      value: settings.autoCacheEnabled,
                      onChanged: (val) => controller.toggleAutoCache(val),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Download on Wi-Fi Only',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      activeTrackColor: tokens.accent,
                      activeThumbColor: tokens.onAccent,
                      value: settings.wifiOnlyDownload,
                      onChanged: (val) => controller.toggleWifiOnly(val),
                    ),
                    ListTile(
                      title: Text(
                        'Clear Cache',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      subtitle: Text(
                        'Removes all unpinned downloaded tracks',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                      leading: Icon(
                        Icons.delete_outline,
                        color: tokens.textPrimary,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: tokens.raised,
                            title: Text(
                              'Clear Cache?',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: tokens.textPrimary),
                            ),
                            content: Text(
                              'This will delete all unpinned downloaded tracks.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  controller.clearCache();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Cache cleared'),
                                      backgroundColor: tokens.raised,
                                    ),
                                  );
                                },
                                child: Text(
                                  'CLEAR',
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(tokens, 'Playback'),
              _buildCard(
                tokens,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Resume on Startup',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      activeTrackColor: tokens.accent,
                      activeThumbColor: tokens.onAccent,
                      value: settings.resumeOnStartup,
                      onChanged: (val) => controller.toggleResumeOnStartup(val),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Pause on Audio Focus Loss',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      subtitle: Text(
                        'Duck 50% for nav, pause for call/headset',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                      activeTrackColor: tokens.accent,
                      activeThumbColor: tokens.onAccent,
                      value: settings.audioFocusPause,
                      onChanged: (val) => controller.toggleAudioFocusPause(val),
                    ),
                    Divider(color: tokens.border, height: 1),
                    ListTile(
                      title: Text(
                        'Crossfade',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                      subtitle: Text(
                        settings.crossfadeSeconds.clamp(0, 12) == 0
                            ? 'Gapless (0s)'
                            : '${settings.crossfadeSeconds.clamp(0, 12)}s crossfade',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                    Semantics(
                      label: 'Crossfade',
                      child: SizedBox(
                        height: 48,
                        child: Slider(
                          activeColor: tokens.accent,
                          inactiveColor: tokens.track,
                          value:
                              settings.crossfadeSeconds.clamp(0, 12).toDouble(),
                          min: 0,
                          max: 12,
                          divisions: 6,
                          label: settings.crossfadeSeconds.clamp(0, 12) == 0
                              ? 'Gapless'
                              : '${settings.crossfadeSeconds.clamp(0, 12)}s',
                          onChanged: (val) =>
                              controller.setCrossfade(val.toInt()),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gapless',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                          Text(
                            '12s',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(tokens, 'Appearance'),
              _buildCard(
                tokens,
                child: ListTile(
                  title: Text(
                    'Theme',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                  subtitle: Text(
                    _themeModeLabel(settings.appThemeMode),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: tokens.textPrimary,
                  ),
                  onTap: () => _pickThemeMode(
                    context,
                    tokens,
                    theme,
                    controller,
                    settings.appThemeMode,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.accent),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: tokens.textPrimary),
          ),
        ),
      ),
    );
  }

  Future<void> _pickThemeMode(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    SettingsController controller,
    AppThemeMode current,
  ) async {
    final choice = await showDialog<AppThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          'Theme',
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        children: [
          for (final mode in AppThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, mode),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _themeModeLabel(mode),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    if (mode == current)
                      Icon(Icons.check, size: 18, color: tokens.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (choice != null && choice != current) {
      await controller.setThemeMode(choice);
    }
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  Widget _buildSectionTitle(AppColorTokens tokens, String title) {
    return Padding(
      padding:
          const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline(tokens),
      ),
    );
  }

  Widget _buildCard(AppColorTokens tokens, {required Widget child}) {
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
