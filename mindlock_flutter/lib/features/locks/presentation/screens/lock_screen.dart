import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../routes/app_routes.dart';
import '../providers/lock_screen_provider.dart';
import '../widgets/unlock_method_card.dart';
import '../widgets/lock_app_header.dart';
import '../widgets/usage_bar.dart';

class LockScreen extends ConsumerStatefulWidget {
  final String packageName;

  const LockScreen({super.key, required this.packageName});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(lockScreenStateProvider(widget.packageName));

    return Scaffold(
      backgroundColor: AppColors.black,
      body: lockState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context),
        data: (state) => _buildLockContent(context, state),
      ),
    );
  }

  Widget _buildLockContent(BuildContext context, LockScreenState state) {
    return SafeArea(
      child: Column(
        children: [
          LockAppHeader(
            appName: state.appName,
            packageName: widget.packageName,
            pulseAnimation: _pulseAnimation,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: UsageBar(
              usedSeconds: state.usedSeconds,
              limitSeconds: state.limitSeconds,
            ),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            '${MindLockDateUtils.formatDurationSeconds(state.usedSeconds)} of '
            '${MindLockDateUtils.formatDurationSeconds(state.limitSeconds)} used today',
            style: AppTypography.bodySmall,
          ),
          AppSpacing.vGap(AppSpacing.xxl),
          _buildMotivationalSection(state),
          AppSpacing.vGap(AppSpacing.xxl),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earn back access', style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.0,
                  )),
                  AppSpacing.vGap(AppSpacing.md),
                  ...state.availableMethods.map((method) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: UnlockMethodCard(
                      method: method,
                      onTap: () => _handleUnlockMethodTap(context, method, state),
                    ),
                  )),
                  if (state.canUseEmergencyUnlock) ...[
                    AppSpacing.vGap(AppSpacing.lg),
                    _buildEmergencyUnlockButton(context, state),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalSection(LockScreenState state) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              state.motivationalMessage,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.recoveredMinutesToday > 0) ...[
              AppSpacing.vGap(AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: AppColors.recoveredTime, size: 16),
                  AppSpacing.hGap(AppSpacing.xs),
                  Text(
                    'You\'ve recovered ${state.recoveredMinutesToday}m today',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.recoveredTime),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyUnlockButton(BuildContext context, LockScreenState state) {
    return GestureDetector(
      onTap: () => _handleEmergencyUnlock(context, state),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
            AppSpacing.hGap(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Unlock', style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error,
                  )),
                  Text('Use only when absolutely necessary',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.error.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }

  void _handleUnlockMethodTap(BuildContext context, UnlockMethod method, LockScreenState state) {
    switch (method.type) {
      case UnlockMethodType.challenge:
      case UnlockMethodType.reflection:
      case UnlockMethodType.learningTask:
      case UnlockMethodType.miniChallenge:
      case UnlockMethodType.habitTask:
        context.push('${AppRoutes.challenge}?id=${method.challengeId}&package=${widget.packageName}');
        break;
      case UnlockMethodType.focusTimer:
      case UnlockMethodType.delayTimer:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${method.title}: ${method.rewardMinutes}m reward')),
        );
        break;
    }
  }

  void _handleEmergencyUnlock(BuildContext context, LockScreenState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Emergency Unlock?'),
        content: Text(
          'This will be recorded and affects your recovery score. '
          'Are you sure you need to open ${state.appName} right now?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(lockScreenStateProvider(widget.packageName).notifier)
                  .useEmergencyUnlock();
              context.pop();
            },
            child: Text('Unlock', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) => const Center(
    child: Text('Error loading lock screen'),
  );
}
