import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/storage/prefs_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../routes/app_routes.dart';

class _OnboardingStep {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String description;
  final List<_FeatureBullet> bullets;

  const _OnboardingStep({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.description,
    this.bullets = const [],
  });
}

class _FeatureBullet {
  final IconData icon;
  final String text;
  const _FeatureBullet(this.icon, this.text);
}

const _steps = [
  _OnboardingStep(
    icon: Icons.remove_red_eye_outlined,
    iconColor: AppColors.brandPrimary,
    iconBg: Color(0xFF1A1730),
    title: 'Take back your focus',
    subtitle: 'See exactly where your time goes',
    description:
        'MindLock tracks your screen time with brutal honesty — so you can finally understand your digital habits and start changing them.',
    bullets: [
      _FeatureBullet(Icons.bar_chart_rounded, 'Detailed daily & weekly reports'),
      _FeatureBullet(Icons.notifications_none_rounded, 'Usage alerts when you overdo it'),
      _FeatureBullet(Icons.trending_down_rounded, 'Watch your screen time shrink'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.shield_outlined,
    iconColor: AppColors.brandSecondary,
    iconBg: Color(0xFF0F2828),
    title: 'Set your boundaries',
    subtitle: 'Block distracting apps on your terms',
    description:
        'Choose which apps to limit and when. Set daily time budgets, schedule focus hours, and let MindLock enforce the rules so you don\'t have to.',
    bullets: [
      _FeatureBullet(Icons.timer_outlined, 'Daily time limits per app'),
      _FeatureBullet(Icons.schedule_rounded, 'Scheduled focus windows'),
      _FeatureBullet(Icons.lock_clock_outlined, 'Delay timers to break the reflex'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.local_fire_department_outlined,
    iconColor: AppColors.streak,
    iconBg: Color(0xFF2A2000),
    title: 'Build real discipline',
    subtitle: 'Turn willpower into a daily habit',
    description:
        'Streaks, challenges, and milestones keep you accountable. Every day you stay on track builds the mental muscle to resist distraction.',
    bullets: [
      _FeatureBullet(Icons.military_tech_outlined, 'Daily streak tracking'),
      _FeatureBullet(Icons.emoji_events_outlined, 'Unlock challenges & achievements'),
      _FeatureBullet(Icons.group_outlined, 'Compare with your past self'),
    ],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _onGetStarted();
    }
  }

  Future<void> _onGetStarted() async {
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    } catch (_) {}

    ref.read(authStateNotifierProvider.notifier).setOnboardingComplete();

    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  void _onSkip() => _onGetStarted();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step indicator text
                  Text(
                    '${_currentPage + 1} of ${_steps.length}',
                    style: AppTypography.labelSmall,
                  ),
                  // Skip button (hide on last page)
                  if (_currentPage < _steps.length - 1)
                    GestureDetector(
                      onTap: _onSkip,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          'Skip',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(step: _steps[index]);
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.brandPrimary
                              : AppColors.border,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                      );
                    }),
                  ),
                  AppSpacing.vGap(AppSpacing.xxl),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _steps.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: AppTypography.button,
                          ),
                          AppSpacing.hGap(AppSpacing.sm),
                          Icon(
                            _currentPage == _steps.length - 1
                                ? Icons.rocket_launch_outlined
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingStep step;

  const _OnboardingPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.vGap(AppSpacing.xl),
          // Illustration area
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: step.iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.iconColor.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: step.iconColor.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(step.icon, size: 64, color: step.iconColor),
            ),
          ),
          AppSpacing.vGap(AppSpacing.huge),
          // Title
          Text(step.title, style: AppTypography.h1),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            step.subtitle,
            style: AppTypography.h3.copyWith(
              color: step.iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.vGap(AppSpacing.lg),
          Text(step.description, style: AppTypography.bodyMedium),
          AppSpacing.vGap(AppSpacing.xxl),
          // Feature bullets
          if (step.bullets.isNotEmpty)
            Container(
              padding: AppSpacing.cardPaddingLarge,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: step.bullets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final bullet = entry.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: step.iconBg,
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: Icon(bullet.icon,
                                size: 18, color: step.iconColor),
                          ),
                          AppSpacing.hGap(AppSpacing.md),
                          Expanded(
                            child: Text(
                              bullet.text,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (i < step.bullets.length - 1) ...[
                        AppSpacing.vGap(AppSpacing.md),
                        const Divider(color: AppColors.border, height: 1),
                        AppSpacing.vGap(AppSpacing.md),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          AppSpacing.vGap(AppSpacing.xxl),
        ],
      ),
    );
  }
}
