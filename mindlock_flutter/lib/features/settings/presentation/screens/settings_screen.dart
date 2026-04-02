import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authStateNotifierProvider);
    final entitlement = ref.watch(entitlementServiceProvider);
    final isPro = entitlement.isPro;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            floating: true,
            pinned: false,
            elevation: 0,
            title: Text('Settings', style: AppTypography.h2),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Section ─────────────────────────────────────
                SettingsSection(
                  title: 'Profile',
                  children: [
                    _ProfileTile(
                      authState: authState,
                      onTap: () => context.push(AppRoutes.profile),
                    ),
                  ],
                ),

                // ── Notifications Section ────────────────────────────────
                SettingsSection(
                  title: 'Notifications',
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Reminders and alerts on your device',
                      value: settings.pushNotificationsEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setPushNotifications(v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Weekly summaries and tips',
                      value: settings.emailNotificationsEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setEmailNotifications(v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.local_fire_department_outlined,
                      iconColor: AppColors.streak,
                      title: 'Streak Alerts',
                      subtitle: 'Remind me before losing my streak',
                      value: settings.streakAlertsEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setStreakAlerts(v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.bar_chart_outlined,
                      iconColor: AppColors.brandSecondary,
                      title: 'Weekly Report',
                      subtitle: 'Summary of your progress every week',
                      value: settings.weeklyReportEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setWeeklyReport(v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emoji_events_outlined,
                      iconColor: AppColors.brandPrimary,
                      title: 'Challenge Reminders',
                      subtitle: 'Nudges to complete daily challenges',
                      value: settings.challengeRemindersEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setChallengeReminders(v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.warning_amber_outlined,
                      iconColor: AppColors.warning,
                      title: 'Limit Warnings',
                      subtitle: 'Alert when approaching screen time limit',
                      value: settings.limitWarningsEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setLimitWarnings(v),
                    ),
                  ],
                ),

                // ── App Section ──────────────────────────────────────────
                SettingsSection(
                  title: 'App',
                  children: [
                    SettingsTile(
                      icon: Icons.schedule_outlined,
                      title: 'Timezone',
                      subtitle: settings.timezone,
                      showArrow: true,
                      onTap: () => _showTimezoneDialog(context, settings.timezone),
                    ),
                    SettingsTile(
                      icon: Icons.cleaning_services_outlined,
                      iconColor: AppColors.warning,
                      title: 'Clear Local Data',
                      subtitle: 'Remove cached usage data from this device',
                      showArrow: true,
                      onTap: () => _confirmClearData(context),
                    ),
                    SettingsTile(
                      icon: Icons.download_outlined,
                      iconColor: AppColors.brandSecondary,
                      title: 'Export My Data',
                      subtitle: 'Download a copy of your data',
                      showArrow: true,
                      onTap: () => _showExportPlaceholder(context),
                    ),
                  ],
                ),

                // ── Subscription Section ─────────────────────────────────
                SettingsSection(
                  title: 'Subscription',
                  children: [
                    SettingsTile(
                      icon: isPro ? Icons.workspace_premium : Icons.star_outline,
                      iconColor: isPro ? AppColors.proBadgeGold : AppColors.textTertiary,
                      title: 'Current Plan',
                      subtitle: isPro ? 'MindLock Pro' : 'Free Plan',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isPro ? AppColors.proBadgeSurface : AppColors.surfaceElevated,
                          borderRadius: AppSpacing.borderRadiusFull,
                          border: Border.all(
                            color: isPro
                                ? AppColors.proBadgeGold.withOpacity(0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isPro ? 'PRO' : 'FREE',
                          style: AppTypography.labelSmall.copyWith(
                            color: isPro ? AppColors.proBadgeGold : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    if (!isPro)
                      SettingsTile(
                        icon: Icons.rocket_launch_outlined,
                        iconColor: AppColors.brandPrimary,
                        title: 'Upgrade to Pro',
                        subtitle: 'Unlock all features and remove limits',
                        showArrow: true,
                        onTap: () => context.push(AppRoutes.paywall),
                      ),
                    if (isPro)
                      SettingsTile(
                        icon: Icons.credit_card_outlined,
                        title: 'Manage Subscription',
                        subtitle: 'View billing and renewal details',
                        showArrow: true,
                        onTap: () => _launchUrl('https://mindlock.app/billing'),
                      ),
                  ],
                ),

                // ── About Section ────────────────────────────────────────
                SettingsSection(
                  title: 'About',
                  children: [
                    SettingsTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      showArrow: true,
                      onTap: () => _launchUrl('https://mindlock.app/privacy'),
                    ),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      showArrow: true,
                      onTap: () => _launchUrl('https://mindlock.app/terms'),
                    ),
                    SettingsTile(
                      icon: Icons.star_rate_outlined,
                      iconColor: AppColors.streak,
                      title: 'Rate the App',
                      showArrow: true,
                      onTap: () => _launchUrl('https://mindlock.app/rate'),
                    ),
                  ],
                ),

                // ── Danger Zone ──────────────────────────────────────────
                SettingsSection(
                  title: 'Danger Zone',
                  children: [
                    SettingsTile(
                      icon: Icons.logout,
                      iconColor: AppColors.error,
                      title: 'Log Out',
                      onTap: () => _confirmLogout(context),
                      trailing: settings.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandPrimary,
                              ),
                            )
                          : null,
                    ),
                    SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      iconColor: AppColors.error,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and all data',
                      showArrow: true,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ],
                ),

                AppSpacing.vGap(AppSpacing.huge),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showTimezoneDialog(BuildContext context, String current) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Timezone', style: AppTypography.h3),
        content: Text(
          'Current: $current\n\nTimezone selection coming soon.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.brandPrimary)),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Clear Local Data?', style: AppTypography.h3),
        content: Text(
          'This will remove all cached usage data from this device. '
          'Your account data on the server will not be affected.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).clearLocalData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local data cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showExportPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export coming soon'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Log Out?', style: AppTypography.h3),
        content: Text(
          'You will need to sign in again to access MindLock.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateNotifierProvider.notifier).logout();
              if (mounted) context.go(AppRoutes.welcome);
            },
            child: Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Delete Account?', style: AppTypography.h3),
        content: Text(
          'This action is permanent and cannot be undone. '
          'All your data will be removed from our servers.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion coming soon. Contact support@mindlock.app'),
                  backgroundColor: AppColors.errorSurface,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: AppColors.errorSurface,
          ),
        );
      }
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final AuthState authState;
  final VoidCallback onTap;

  const _ProfileTile({required this.authState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = authState.userName ?? 'Your Name';
    final email = authState.userEmail ?? '';
    final avatar = authState.userAvatar;

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.brandPrimary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppTypography.h3.copyWith(color: AppColors.brandPrimary),
                    )
                  : null,
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.labelLarge),
                  if (email.isNotEmpty) Text(email, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
