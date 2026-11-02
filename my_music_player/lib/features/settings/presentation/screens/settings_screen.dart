import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/enums.dart';
import '../providers/settings_provider.dart';
import '../../../cache/presentation/providers/cache_stats_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(appSettingsProvider);
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final controller = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final cacheMb = settings.maxCacheSizeBytes / (1024 * 1024);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSectionTitle(theme, 'Server'),
              _buildCard(
                child: ListTile(
                  title: const Text('Backend URL',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(settings.backendBaseUrl,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  trailing:
                      const Icon(Icons.edit, color: AppColors.textSecondary),
                  onTap: () {
                    final textController =
                        TextEditingController(text: settings.backendBaseUrl);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceElevated,
                        title: const Text('Edit Backend URL',
                            style: TextStyle(color: AppColors.textPrimary)),
                        content: TextField(
                          controller: textController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'http://123.45.67.89:8000',
                            hintStyle:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCEL',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              controller
                                  .updateBackendUrl(textController.text.trim());
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Backend URL updated'),
                                    backgroundColor: AppColors.surfaceOverlay),
                              );
                            },
                            child: const Text('SAVE',
                                style:
                                    TextStyle(color: AppColors.accentPrimary)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(theme, 'Sources'),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable YouTube Source',
                          style: TextStyle(color: AppColors.textPrimary)),
                      activeTrackColor: AppColors.accentPrimary,
                      value: settings.enableYoutubeSource,
                      onChanged: (val) => controller.toggleYoutubeSource(val),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Jamendo Source',
                          style: TextStyle(color: AppColors.textPrimary)),
                      activeThumbColor: AppColors.accentPrimary,
                      value: settings.enableJamendoSource,
                      onChanged: (val) => controller.toggleJamendoSource(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(theme, 'Audio'),
              _buildCard(
                child: ListTile(
                  title: const Text('Preferred Audio Quality',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: DropdownButton<AudioQuality>(
                    dropdownColor: AppColors.surfaceElevated,
                    value: settings.preferredAudioQuality,
                    style: const TextStyle(color: AppColors.textPrimary),
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
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(theme, 'Cache'),
              _buildCard(
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
                              title: const Text('Storage Used',
                                  style:
                                      TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text(
                                '${usedMb.toStringAsFixed(1)} MB / ${maxMb.toInt()} MB ($pct%) • ${stats.totalCachedTracks} tracks${stats.pinnedTrackIds.isNotEmpty ? ' • ${stats.pinnedTrackIds.length} pinned' : ''}',
                                style: TextStyle(
                                    color: stats.isNearLimit
                                        ? AppColors.statusWarning
                                        : AppColors.textSecondary),
                              ),
                            ),
                            LinearProgressIndicator(
                              value: stats.usagePercentage.clamp(0.0, 1.0),
                              backgroundColor: AppColors.surfaceOverlay,
                              color: stats.isOverLimit
                                  ? AppColors.statusError
                                  : stats.isNearLimit
                                      ? AppColors.statusWarning
                                      : AppColors.accentPrimary,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    ListTile(
                      title: const Text('Max Cache Size',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('${cacheMb.toInt()} MB',
                          style:
                              const TextStyle(color: AppColors.accentPrimary)),
                    ),
                    Slider(
                      activeColor: AppColors.accentPrimary,
                      inactiveColor: AppColors.surfaceOverlay,
                      value: cacheMb.clamp(250, 10000),
                      min: 250,
                      max: 10000,
                      divisions: 39,
                      label: '${cacheMb.toInt()} MB',
                      onChanged: (val) {
                        controller.setCacheLimitMb(val.toInt());
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Auto-Cache on Play',
                          style: TextStyle(color: AppColors.textPrimary)),
                      activeThumbColor: AppColors.accentPrimary,
                      value: settings.autoCacheEnabled,
                      onChanged: (val) => controller.toggleAutoCache(val),
                    ),
                    SwitchListTile(
                      title: const Text('Download on Wi-Fi Only',
                          style: TextStyle(color: AppColors.textPrimary)),
                      activeThumbColor: AppColors.accentPrimary,
                      value: settings.wifiOnlyDownload,
                      onChanged: (val) => controller.toggleWifiOnly(val),
                    ),
                    ListTile(
                      title: const Text('Clear Cache',
                          style: TextStyle(color: AppColors.statusError)),
                      subtitle: const Text(
                          'Removes all unpinned downloaded tracks',
                          style: TextStyle(color: AppColors.textSecondary)),
                      leading: const Icon(Icons.delete_outline,
                          color: AppColors.statusError),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceElevated,
                            title: const Text('Clear Cache?',
                                style: TextStyle(color: AppColors.textPrimary)),
                            content: const Text(
                                'This will delete all unpinned downloaded tracks.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('CANCEL',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  controller.clearCache();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cache cleared'),
                                        backgroundColor:
                                            AppColors.surfaceOverlay),
                                  );
                                },
                                child: const Text('CLEAR',
                                    style: TextStyle(
                                        color: AppColors.statusError)),
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
              _buildSectionTitle(theme, 'Playback'),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Resume on Startup',
                          style: TextStyle(color: AppColors.textPrimary)),
                      activeThumbColor: AppColors.accentPrimary,
                      value: settings.resumeOnStartup,
                      onChanged: (val) => controller.toggleResumeOnStartup(val),
                    ),
                    SwitchListTile(
                      title: const Text('Pause on Audio Focus Loss',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: const Text(
                          'Duck 50% for nav, pause for call/headset',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      activeThumbColor: AppColors.accentPrimary,
                      value: settings.audioFocusPause,
                      onChanged: (val) => controller.toggleAudioFocusPause(val),
                    ),
                    const Divider(color: AppColors.surfaceOverlay, height: 1),
                    ListTile(
                      title: const Text('Crossfade',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(
                        settings.crossfadeSeconds.clamp(0, 12) == 0
                            ? 'Gapless (0s)'
                            : '${settings.crossfadeSeconds.clamp(0, 12)}s crossfade',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Slider(
                      activeColor: AppColors.accentPrimary,
                      inactiveColor: AppColors.surfaceOverlay,
                      value: settings.crossfadeSeconds.clamp(0, 12).toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 6,
                      label: settings.crossfadeSeconds.clamp(0, 12) == 0
                          ? 'Gapless'
                          : '${settings.crossfadeSeconds.clamp(0, 12)}s',
                      onChanged: (val) => controller.setCrossfade(val.toInt()),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gapless',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          Text('12s',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary)),
        error: (e, st) => const Center(
            child: Text('Error: \$e',
                style: TextStyle(color: AppColors.statusError))),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding:
          const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.accentPrimary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
