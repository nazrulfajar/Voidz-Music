import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../cache/presentation/providers/cache_stats_provider.dart';
import '../providers/settings_provider.dart';

/// Settings screen laid out as PLAYBACK, DOWNLOADS, APPEARANCE, ABOUT
/// (`docs/DESIGN_SYSTEM.md` §6.6, screen 17).
///
/// The YouTube source toggle is a sub-row of Playback instead of a separate
/// Sources section: PRD F7.2 keeps the toggle, while design 17 has no source
/// section. This is the documented deviation for TASK-030.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _crossfadeOptions = [0, 2, 4, 6, 8, 10, 12];

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
          final crossfade = settings.crossfadeSeconds.clamp(0, 12);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenInset,
              AppSpacing.space2,
              AppSpacing.screenInset,
              AppSpacing.space12,
            ),
            children: [
              _buildSectionTitle(tokens, 'Playback'),
              _buildGroup(tokens, [
                _SettingsRow(
                  label: 'Audio quality',
                  value: _qualityLabel(settings.preferredAudioQuality),
                  showChevron: true,
                  onTap: () => _pickAudioQuality(
                    context,
                    tokens,
                    theme,
                    controller,
                    settings.preferredAudioQuality,
                  ),
                ),
                _SettingsRow(
                  label: 'Gapless / Crossfade',
                  value: crossfade == 0 ? 'Gapless' : '${crossfade}s',
                  showChevron: true,
                  onTap: () => _pickCrossfade(
                    context,
                    tokens,
                    theme,
                    controller,
                    crossfade,
                  ),
                ),
                _SettingsRow(
                  label: 'Resume on startup',
                  value: _onOff(settings.resumeOnStartup),
                  isToggle: true,
                  toggled: settings.resumeOnStartup,
                  onTap: () => controller.toggleResumeOnStartup(
                    !settings.resumeOnStartup,
                  ),
                ),
                _SettingsRow(
                  label: 'Audio focus',
                  subtitle: 'Duck 50% for nav, pause for call/headset',
                  value: _onOff(settings.audioFocusPause),
                  isToggle: true,
                  toggled: settings.audioFocusPause,
                  onTap: () => controller.toggleAudioFocusPause(
                    !settings.audioFocusPause,
                  ),
                ),
                _SettingsRow(
                  label: 'YouTube source',
                  subtitle: 'Search and stream from YouTube Music',
                  value: _onOff(settings.enableYoutubeSource),
                  isToggle: true,
                  toggled: settings.enableYoutubeSource,
                  onTap: () => controller.toggleYoutubeSource(
                    !settings.enableYoutubeSource,
                  ),
                ),
              ]),
              _buildSectionTitle(tokens, 'Downloads'),
              _buildGroup(tokens, [
                _SettingsRow(
                  label: 'Wi-Fi only',
                  value: _onOff(settings.wifiOnlyDownload),
                  isToggle: true,
                  toggled: settings.wifiOnlyDownload,
                  onTap: () => controller.toggleWifiOnly(
                    !settings.wifiOnlyDownload,
                  ),
                ),
                _SettingsRow(
                  label: 'Storage limit',
                  value: _formatStorageLimit(cacheMb),
                  showChevron: true,
                  onTap: () => _pickStorageLimit(
                    context,
                    tokens,
                    theme,
                    controller,
                    cacheMb,
                  ),
                ),
                cacheStatsAsync.when(
                  data: (stats) => _SettingsRow(
                    label: 'Storage used',
                    value: '${_formatBytes(stats.totalCacheSizeBytes)} / '
                        '${_formatBytes(stats.maxCacheSizeBytes)}',
                    subtitle: '${stats.totalCachedTracks} tracks'
                        '${stats.pinnedTrackIds.isNotEmpty ? ' • '
                            '${stats.pinnedTrackIds.length} pinned' : ''}',
                  ),
                  loading: () => const _SettingsRow(
                    label: 'Storage used',
                    value: '...',
                  ),
                  error: (_, __) => const _SettingsRow(
                    label: 'Storage used',
                    value: 'Unavailable',
                  ),
                ),
                _SettingsRow(
                  label: 'Auto-cache',
                  subtitle: 'Cache tracks automatically when they play',
                  value: _onOff(settings.autoCacheEnabled),
                  isToggle: true,
                  toggled: settings.autoCacheEnabled,
                  onTap: () => controller.toggleAutoCache(
                    !settings.autoCacheEnabled,
                  ),
                ),
                _SettingsRow(
                  label: 'Clear cache',
                  subtitle: 'Removes all unpinned downloaded tracks',
                  showChevron: true,
                  onTap: () =>
                      _confirmClearCache(context, tokens, theme, controller),
                ),
              ]),
              _buildSectionTitle(tokens, 'Appearance'),
              _buildGroup(tokens, [
                _SettingsRow(
                  label: 'Theme',
                  value: _themeModeLabel(settings.appThemeMode),
                  showChevron: true,
                  onTap: () => _pickThemeMode(
                    context,
                    tokens,
                    theme,
                    controller,
                    settings.appThemeMode,
                  ),
                ),
              ]),
              _buildSectionTitle(tokens, 'About'),
              _buildGroup(tokens, [
                const _SettingsRow(label: 'Version', value: appVersion),
                _SettingsRow(
                  label: 'Licenses',
                  showChevron: true,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: appName,
                    applicationVersion: appVersion,
                  ),
                ),
              ]),
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

  Widget _buildSectionTitle(AppColorTokens tokens, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space6,
        bottom: AppSpacing.space2,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline(tokens),
      ),
    );
  }

  Widget _buildGroup(AppColorTokens tokens, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            color: tokens.border,
            height: 1,
            thickness: 1,
            indent: AppSpacing.space4,
            endIndent: AppSpacing.space4,
          ),
        );
      }
      children.add(rows[i]);
    }

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Future<void> _pickAudioQuality(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    SettingsController controller,
    AudioQuality current,
  ) async {
    final choice = await showDialog<AudioQuality>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          'Audio quality',
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        children: [
          for (final quality in AudioQuality.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, quality),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _qualityLabel(quality),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    if (quality == current)
                      Icon(Icons.check, size: 18, color: tokens.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (choice != null && choice != current) {
      await controller.setAudioQuality(choice);
    }
  }

  Future<void> _pickCrossfade(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    SettingsController controller,
    int current,
  ) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          'Gapless / Crossfade',
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        children: [
          for (final seconds in _crossfadeOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, seconds),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        seconds == 0 ? 'Gapless' : '${seconds}s crossfade',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    if (seconds == current)
                      Icon(Icons.check, size: 18, color: tokens.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (choice != null && choice != current) {
      await controller.setCrossfade(choice);
    }
  }

  Future<void> _pickStorageLimit(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    SettingsController controller,
    double currentMb,
  ) async {
    var value = currentMb.clamp(250, 10000).toDouble();

    final choice = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: tokens.raised,
          title: Text(
            'Storage limit',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatStorageLimit(value)} maximum',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
              ),
              SizedBox(
                height: 48,
                child: Slider(
                  activeColor: tokens.accent,
                  inactiveColor: tokens.track,
                  value: value,
                  min: 250,
                  max: 10000,
                  divisions: 39,
                  label: _formatStorageLimit(value),
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCEL',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(
                'SAVE',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      await controller.setCacheLimitMb(choice.round());
    }
  }

  Future<void> _confirmClearCache(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    SettingsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.raised,
        title: Text(
          'Clear cache?',
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        content: Text(
          'This will delete all unpinned downloaded tracks.',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'CLEAR',
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await controller.clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cache cleared'),
            backgroundColor: tokens.raised,
          ),
        );
      }
    }
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

  String _qualityLabel(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return 'Low';
      case AudioQuality.medium:
        return 'Medium';
      case AudioQuality.high:
        return 'High';
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

  String _onOff(bool value) => value ? 'On' : 'Off';

  String _formatStorageLimit(double mb) {
    if (mb < 1000) return '${mb.round()} MB';
    return _formatGb(mb / 1000);
  }

  String _formatBytes(int bytes) {
    const gb = 1024 * 1024 * 1024;
    if (bytes >= gb) return _formatGb(bytes / gb);
    final mb = bytes / (1024 * 1024);
    return '${mb.round()} MB';
  }

  String _formatGb(double value) {
    if (value >= 10) return '${value.round()} GB';
    final fixed = value.toStringAsFixed(1);
    return '${fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed} GB';
  }
}

/// One row of a settings group: label on the left, optional value and chevron
/// on the right. Boolean rows expose a toggled semantic state instead of a
/// switch, matching the value-text design in §6.6.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.value,
    this.subtitle,
    this.onTap,
    this.showChevron = false,
    this.isToggle = false,
    this.toggled,
  });

  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isToggle;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);

    return Semantics(
      button: onTap != null,
      toggled: isToggle ? toggled : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Flexible(
                    flex: 2,
                    child: Text(
                      value!,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (showChevron) ...[
                  const SizedBox(width: AppSpacing.space1),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
