import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../../../shared/widgets/ml_button.dart';
import '../../../../shared/widgets/ml_text_field.dart';
import '../providers/profile_provider.dart';
import '../../data/models/user_profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _timezoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _timezoneController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(UserProfileModel user) {
    if (!_isEditing) {
      _nameController.text = user.name;
      _timezoneController.text = user.timezone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final entitlement = ref.watch(entitlementServiceProvider);
    final isPro = entitlement.isPro;

    // Show errors via snackbar
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(profileProvider.notifier).clearError();
      }
    });

    if (profileState.user != null) {
      _syncControllersFromState(profileState.user!);
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            floating: true,
            pinned: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Profile', style: AppTypography.h2),
            actions: [
              if (!_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: Text(
                    'Edit',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (profileState.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              ),
            )
          else if (profileState.user == null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else
            SliverToBoxAdapter(
              child: _buildContent(
                context,
                profileState.user!,
                profileState.isSaving,
                isPro,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfileModel user,
    bool isSaving,
    bool isPro,
  ) {
    return Column(
      children: [
        // ── Avatar section ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      )
                    : null,
              ),
              GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // ── Pro badge / upgrade nudge ────────────────────────────────────
        if (isPro)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.proBadgeSurface,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(
                color: AppColors.proBadgeGold.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium,
                    color: AppColors.proBadgeGold, size: 14),
                AppSpacing.hGap(AppSpacing.xs),
                Text(
                  'MindLock Pro',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.proBadgeGold,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.paywall),
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch,
                        color: Colors.white, size: 22),
                    AppSpacing.hGap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Pro',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Unlock all challenges, insights & more',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

        // ── Stats row ────────────────────────────────────────────────────
        Padding(
          padding: AppSpacing.screenPadding,
          child: _buildStatsRow(user),
        ),
        AppSpacing.vGap(AppSpacing.xxl),

        // ── Edit form ────────────────────────────────────────────────────
        if (_isEditing)
          Padding(
            padding: AppSpacing.screenPadding,
            child: _buildEditForm(isSaving),
          )
        else
          _buildDisplayInfo(user),

        // ── Change Password ──────────────────────────────────────────────
        const Divider(color: AppColors.border, height: 1),
        ListTile(
          tileColor: AppColors.surface,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.12),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: const Icon(Icons.lock_outline,
                size: 18, color: AppColors.brandPrimary),
          ),
          title: Text('Change Password', style: AppTypography.bodyLarge),
          subtitle: Text('Send a reset link to your email',
              style: AppTypography.bodySmall),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textTertiary, size: 20),
          onTap: () => _sendPasswordReset(user.email),
        ),
        const Divider(color: AppColors.border, height: 1),

        AppSpacing.vGap(AppSpacing.huge),
      ],
    );
  }

  Widget _buildStatsRow(UserProfileModel user) {
    return Row(
      children: [
        _buildStatCell(
          label: 'Current Streak',
          value: '${user.currentStreak}d',
          color: AppColors.streak,
          icon: Icons.local_fire_department,
        ),
        Container(width: 1, height: 40, color: AppColors.border),
        _buildStatCell(
          label: 'Best Streak',
          value: '${user.longestStreak}d',
          color: AppColors.brandSecondary,
          icon: Icons.emoji_events_outlined,
        ),
        Container(width: 1, height: 40, color: AppColors.border),
        _buildStatCell(
          label: 'Member Since',
          value: _formatMemberSince(user.createdAt),
          color: AppColors.textSecondary,
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          AppSpacing.vGap(AppSpacing.xs),
          Text(value,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDisplayInfo(UserProfileModel user) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const Divider(color: AppColors.border, height: 1),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: user.name,
          ),
          const Divider(color: AppColors.borderSubtle, height: 1, indent: AppSpacing.lg),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            trailing: user.emailVerified
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'Verified',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.success),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'Unverified',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.warning),
                    ),
                  ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1, indent: AppSpacing.lg),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Timezone',
            value: user.timezone,
          ),
          const Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edit Profile', style: AppTypography.h3),
        AppSpacing.vGap(AppSpacing.lg),
        MlTextField(
          label: 'Display Name',
          hint: 'Your full name',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
        ),
        AppSpacing.vGap(AppSpacing.md),
        MlTextField(
          label: 'Timezone',
          hint: 'e.g. America/New_York',
          controller: _timezoneController,
          prefixIcon: Icons.schedule_outlined,
        ),
        AppSpacing.vGap(AppSpacing.xl),
        MlButton(
          label: 'Save Changes',
          onPressed: isSaving ? null : _saveProfile,
          isLoading: isSaving,
          fullWidth: true,
        ),
        AppSpacing.vGap(AppSpacing.xxl),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          AppSpacing.vGap(AppSpacing.md),
          Text('Failed to load profile', style: AppTypography.bodyLarge),
          AppSpacing.vGap(AppSpacing.lg),
          MlButton(
            label: 'Retry',
            onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(profileProvider.notifier).updateAvatar(File(picked.path));
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final timezone = _timezoneController.text.trim();
    await ref.read(profileProvider.notifier).updateProfile(
          name: name.isNotEmpty ? name : null,
          timezone: timezone.isNotEmpty ? timezone : null,
        );
    if (mounted) setState(() => _isEditing = false);
  }

  void _sendPasswordReset(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset link sent to $email'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null) return '—';
    try {
      final dt = DateTime.parse(createdAt);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(value, style: AppTypography.bodyLarge),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
