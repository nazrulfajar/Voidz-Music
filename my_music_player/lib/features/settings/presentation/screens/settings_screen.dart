import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_chrome_insets.dart';
import '../../../../shared/widgets/glass_background.dart';
import '../../../../shared/widgets/glass_surface.dart';
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
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(appSettingsProvider);
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final controller = ref.watch(settingsControllerProvider);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.settingsTitle),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.commonBack,
            onPressed: () => context.pop(),
          ),
        ),
        body: settingsAsync.when(
          data: (settings) {
            final cacheMb = settings.maxCacheSizeBytes / (1024 * 1024);
            final crossfade = settings.crossfadeSeconds.clamp(0, 12);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenInset,
                AppSpacing.space2,
                AppSpacing.screenInset,
                math.max(
                  AppSpacing.space12,
                  AppChromeInsets.scrollBottomOf(context) + AppSpacing.space2,
                ),
              ),
              children: [
                _buildSectionTitle(tokens, l10n.settingsSectionPlayback),
                _buildGroup(
                    tokens,
                    [
                      _SettingsRow(
                        label: l10n.settingsAudioQuality,
                        value:
                            _qualityLabel(l10n, settings.preferredAudioQuality),
                        showChevron: true,
                        onTap: () => _pickAudioQuality(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                          settings.preferredAudioQuality,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsGaplessCrossfade,
                        value: crossfade == 0
                            ? l10n.settingsGapless
                            : l10n.settingsCrossfadeValue(crossfade),
                        showChevron: true,
                        onTap: () => _pickCrossfade(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                          crossfade,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsResumeOnStartup,
                        isToggle: true,
                        toggled: settings.resumeOnStartup,
                        onTap: () => controller.toggleResumeOnStartup(
                          !settings.resumeOnStartup,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsAudioFocus,
                        subtitle: l10n.settingsAudioFocusSubtitle,
                        isToggle: true,
                        toggled: settings.audioFocusPause,
                        onTap: () => controller.toggleAudioFocusPause(
                          !settings.audioFocusPause,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsYoutubeSource,
                        subtitle: l10n.settingsYoutubeSourceSubtitle,
                        isToggle: true,
                        toggled: settings.enableYoutubeSource,
                        onTap: () => controller.toggleYoutubeSource(
                          !settings.enableYoutubeSource,
                        ),
                      ),
                    ],
                    key: const Key('settings-group-playback')),
                _buildSectionTitle(tokens, l10n.settingsSectionDownloads),
                _buildGroup(
                    tokens,
                    [
                      _SettingsRow(
                        label: l10n.settingsWifiOnly,
                        isToggle: true,
                        toggled: settings.wifiOnlyDownload,
                        onTap: () => controller.toggleWifiOnly(
                          !settings.wifiOnlyDownload,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsStorageLimit,
                        value: _formatStorageLimit(cacheMb),
                        showChevron: true,
                        onTap: () => _pickStorageLimit(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                          cacheMb,
                        ),
                      ),
                      cacheStatsAsync.when(
                        data: (stats) => _SettingsRow(
                          label: l10n.settingsStorageUsed,
                          value: '${_formatBytes(stats.totalCacheSizeBytes)} / '
                              '${_formatBytes(stats.maxCacheSizeBytes)}',
                          subtitle: _storageSummary(
                            l10n,
                            stats.totalCachedTracks,
                            stats.pinnedTrackIds.length,
                          ),
                        ),
                        loading: () => _SettingsRow(
                          label: l10n.settingsStorageUsed,
                          value: '...',
                        ),
                        error: (_, __) => _SettingsRow(
                          label: l10n.settingsStorageUsed,
                          value: l10n.settingsUnavailable,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsAutoCache,
                        subtitle: l10n.settingsAutoCacheSubtitle,
                        isToggle: true,
                        toggled: settings.autoCacheEnabled,
                        onTap: () => controller.toggleAutoCache(
                          !settings.autoCacheEnabled,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.settingsClearCache,
                        subtitle: l10n.settingsClearCacheSubtitle,
                        showChevron: true,
                        onTap: () => _confirmClearCache(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                        ),
                      ),
                    ],
                    key: const Key('settings-group-downloads')),
                _buildSectionTitle(tokens, l10n.settingsSectionAppearance),
                _buildGroup(
                    tokens,
                    [
                      _SettingsRow(
                        label: l10n.settingsTheme,
                        value: _themeModeLabel(l10n, settings.appThemeMode),
                        showChevron: true,
                        onTap: () => _pickThemeMode(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                          settings.appThemeMode,
                        ),
                      ),
                      _SettingsRow(
                        label: l10n.language,
                        value:
                            _languageModeLabel(l10n, settings.appLanguageMode),
                        showChevron: true,
                        onTap: () => _pickLanguageMode(
                          context,
                          tokens,
                          theme,
                          l10n,
                          controller,
                          settings.appLanguageMode,
                        ),
                      ),
                    ],
                    key: const Key('settings-group-appearance')),
                _buildSectionTitle(tokens, l10n.settingsSectionAbout),
                _buildGroup(
                    tokens,
                    [
                      _SettingsRow(
                        label: l10n.settingsVersion,
                        value: appVersion,
                      ),
                      _SettingsRow(
                        label: l10n.settingsLicenses,
                        showChevron: true,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: appName,
                          applicationVersion: appVersion,
                        ),
                      ),
                    ],
                    key: const Key('settings-group-about')),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.accent),
          ),
          error: (e, st) => Center(
            child: Text(
              l10n.settingsError(e.toString()),
              style: TextStyle(color: tokens.textPrimary),
            ),
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

  Widget _buildGroup(
    AppColorTokens tokens,
    List<Widget> rows, {
    Key? key,
  }) {
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

    // Settings groups are content cards. Four groups on one screen would
    // exceed the 2-3 blurred-layer cap, so the whole screen uses the frosted
    // step: glass fill + glass border without a backdrop filter.
    return GlassSurface.card(
      key: key,
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Future<void> _pickAudioQuality(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    AppLocalizations l10n,
    SettingsController controller,
    AudioQuality current,
  ) async {
    final choice = await showDialog<AudioQuality>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.settingsAudioQuality,
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
                        _qualityLabel(l10n, quality),
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
    AppLocalizations l10n,
    SettingsController controller,
    int current,
  ) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.settingsGaplessCrossfade,
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
                        seconds == 0
                            ? l10n.settingsGapless
                            : l10n.settingsCrossfadeOption(seconds),
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
    AppLocalizations l10n,
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
            l10n.settingsStorageLimit,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsStorageLimitMax(
                  _formatStorageLimit(value),
                ),
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
                l10n.commonCancel,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(
                l10n.commonSave,
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
    AppLocalizations l10n,
    SettingsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.settingsClearCacheTitle,
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        content: Text(
          l10n.settingsClearCacheBody,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.settingsClearCacheConfirm,
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
            content: Text(l10n.settingsCacheCleared),
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
    AppLocalizations l10n,
    SettingsController controller,
    AppThemeMode current,
  ) async {
    final choice = await showDialog<AppThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.settingsTheme,
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
                        _themeModeLabel(l10n, mode),
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

  Future<void> _pickLanguageMode(
    BuildContext context,
    AppColorTokens tokens,
    ThemeData theme,
    AppLocalizations l10n,
    SettingsController controller,
    AppLanguageMode current,
  ) async {
    final choice = await showDialog<AppLanguageMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.language,
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        children: [
          for (final mode in AppLanguageMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, mode),
              child: Semantics(
                selected: mode == current,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _languageModeLabel(l10n, mode),
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
            ),
        ],
      ),
    );

    if (choice != null && choice != current) {
      await controller.setAppLanguageMode(choice);
    }
  }

  String _qualityLabel(AppLocalizations l10n, AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return l10n.settingsQualityLow;
      case AudioQuality.medium:
        return l10n.settingsQualityMedium;
      case AudioQuality.high:
        return l10n.settingsQualityHigh;
    }
  }

  String _themeModeLabel(AppLocalizations l10n, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return l10n.settingsThemeSystem;
      case AppThemeMode.light:
        return l10n.settingsThemeLight;
      case AppThemeMode.dark:
        return l10n.settingsThemeDark;
    }
  }

  String _languageModeLabel(AppLocalizations l10n, AppLanguageMode mode) {
    switch (mode) {
      case AppLanguageMode.system:
        return l10n.languageSystem;
      case AppLanguageMode.english:
        return l10n.languageEnglish;
      case AppLanguageMode.indonesian:
        return l10n.languageIndonesian;
    }
  }

  String _storageSummary(AppLocalizations l10n, int tracks, int pinned) {
    final trackCount = l10n.settingsTrackCount(tracks);
    if (pinned == 0) return trackCount;
    return '$trackCount • ${l10n.settingsPinnedCount(pinned)}';
  }

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
/// on the right. Boolean rows render a visible switch (`DESIGN_SYSTEM.md` §6.6)
/// and expose a single toggled semantic node with no duplicate value text.
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
    final enabled = onTap != null;

    final row = ConstrainedBox(
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
                        color: enabled ? tokens.textPrimary : tokens.textMuted,
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
              if (isToggle) ...[
                const SizedBox(width: AppSpacing.space2),
                Switch(
                  value: toggled ?? false,
                  onChanged: enabled ? (_) => onTap!() : null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ] else if (value != null) ...[
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
    );

    if (isToggle) {
      return Semantics(
        container: true,
        button: true,
        enabled: enabled,
        toggled: toggled,
        label: subtitle == null ? label : '$label. $subtitle',
        onTap: enabled ? onTap : null,
        child: ExcludeSemantics(child: row),
      );
    }

    return Semantics(
      button: enabled,
      enabled: enabled,
      child: row,
    );
  }
}
