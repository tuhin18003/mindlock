import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ml_button.dart';
import '../providers/challenge_provider.dart';
import '../../data/models/challenge_model.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  final String challengeId;
  final String? packageName;

  const ChallengeScreen({
    super.key,
    required this.challengeId,
    this.packageName,
  });

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _successController;
  late Animation<double> _successFadeAnimation;

  final TextEditingController _reflectionController = TextEditingController();
  int? _selectedQuizAnswer;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successFadeAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = int.tryParse(widget.challengeId) ?? 0;
      ref.read(challengeProvider(widget.challengeId).notifier).loadChallenge(
            id,
            widget.packageName,
          );
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _successController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider(widget.challengeId));

    // Trigger success animation when phase changes to completed
    ref.listen<ChallengeState>(challengeProvider(widget.challengeId),
        (prev, next) {
      if (next.phase == ChallengePhase.completed &&
          prev?.phase != ChallengePhase.completed) {
        _successController.forward();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Builder(builder: (_) {
          if (challengeState.challenge == null &&
              challengeState.error == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            );
          }

          if (challengeState.error != null &&
              challengeState.challenge == null) {
            return _buildLoadError(challengeState.error!);
          }

          return switch (challengeState.phase) {
            ChallengePhase.intro => _buildIntroPhase(challengeState),
            ChallengePhase.active => _buildActivePhase(challengeState),
            ChallengePhase.completed => _buildCompletedPhase(challengeState),
            ChallengePhase.failed => _buildFailedPhase(challengeState),
          };
        }),
      ),
    );
  }

  // ── INTRO PHASE ────────────────────────────────────────────────────────────

  Widget _buildIntroPhase(ChallengeState state) {
    final challenge = state.challenge!;
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingFull,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.textSecondary),
                AppSpacing.hGap(AppSpacing.xs),
                Text('Go Back', style: AppTypography.bodyMedium),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.xxxl),

          // Type icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Center(
              child: Text(
                _typeEmoji(challenge.type),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          AppSpacing.vGap(AppSpacing.lg),

          // Category
          if (challenge.categoryName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                challenge.categoryName!.toUpperCase(),
                style: AppTypography.overline,
              ),
            ),

          // Title
          Text(challenge.title, style: AppTypography.h1),
          AppSpacing.vGap(AppSpacing.md),

          // Description
          Text(challenge.description, style: AppTypography.bodyLarge),
          AppSpacing.vGap(AppSpacing.xl),

          // Badges row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _badge(
                label: _difficultyLabel(challenge.difficulty),
                color: _difficultyColor(challenge.difficulty),
              ),
              _badge(
                label: '+${challenge.rewardMinutes}m unlock',
                color: AppColors.brandPrimary,
                icon: Icons.bolt,
              ),
              _badge(
                label: _formatDuration(challenge.durationSeconds),
                color: AppColors.textTertiary,
                icon: Icons.timer_outlined,
              ),
              if (challenge.isPro)
                _badge(
                  label: 'PRO',
                  color: AppColors.proBadgeGold,
                  icon: Icons.workspace_premium,
                ),
            ],
          ),
          AppSpacing.vGap(AppSpacing.huge),

          // Start button
          MlButton(
            label: 'Start Challenge',
            onPressed: () {
              ref
                  .read(challengeProvider(widget.challengeId).notifier)
                  .startChallenge();
            },
            fullWidth: true,
            size: MlButtonSize.lg,
            leadingIcon: Icons.play_arrow_rounded,
          ),
          AppSpacing.vGap(AppSpacing.md),

          // Go back link
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Go back to lock screen',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIVE PHASE ───────────────────────────────────────────────────────────

  Widget _buildActivePhase(ChallengeState state) {
    final challenge = state.challenge!;
    return Column(
      children: [
        // Header
        Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: AppTypography.h3),
                    Text(challenge.type, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              _TimerDisplay(remainingSeconds: state.remainingSeconds),
            ],
          ),
        ),

        // Progress bar
        LinearProgressIndicator(
          value: challenge.durationSeconds > 0
              ? state.remainingSeconds / challenge.durationSeconds
              : 0.0,
          backgroundColor: AppColors.surfaceElevated,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          minHeight: 3,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPaddingFull,
            child: Column(
              children: [
                AppSpacing.vGap(AppSpacing.lg),
                _buildChallengeBody(challenge, state),
              ],
            ),
          ),
        ),

        // Give up button
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: MlButton(
            label: 'Give Up',
            onPressed: state.isSubmitting
                ? null
                : () => _confirmGiveUp(context),
            variant: MlButtonVariant.ghost,
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeBody(ChallengeModel challenge, ChallengeState state) {
    switch (challenge.type) {
      case 'breathing':
        return _buildBreathingChallenge(challenge, state);
      case 'reflection':
        return _buildReflectionChallenge(challenge, state);
      case 'quiz':
        return _buildQuizChallenge(challenge, state);
      default:
        return _buildReflectionChallenge(challenge, state);
    }
  }

  Widget _buildBreathingChallenge(
      ChallengeModel challenge, ChallengeState state) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, _) {
            final scale = _breathingAnimation.value;
            final label =
                scale > 0.8 ? 'Breathe In...' : 'Breathe Out...';
            return Column(
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary.withOpacity(0.08),
                          ),
                        ),
                      ),
                      // Middle ring
                      Transform.scale(
                        scale: scale * 0.85,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary.withOpacity(0.15),
                          ),
                        ),
                      ),
                      // Core
                      Transform.scale(
                        scale: scale * 0.65,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                          ),
                          child: const Icon(
                            Icons.air,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGap(AppSpacing.xxl),
                Text(
                  label,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            );
          },
        ),
        AppSpacing.vGap(AppSpacing.xl),
        Text(
          challenge.content?['instruction'] as String? ??
              'Follow the rhythm of the circle. Breathe in as it expands, out as it contracts.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReflectionChallenge(
      ChallengeModel challenge, ChallengeState state) {
    final prompt = challenge.content?['prompt'] as String? ??
        challenge.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_quote,
                      color: AppColors.brandPrimary, size: 20),
                  AppSpacing.hGap(AppSpacing.sm),
                  Text('Reflection Prompt',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.brandPrimary,
                      )),
                ],
              ),
              AppSpacing.vGap(AppSpacing.md),
              Text(prompt, style: AppTypography.bodyLarge),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.lg),
        TextField(
          controller: _reflectionController,
          maxLines: 5,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Type your reflection here...',
            hintStyle: AppTypography.bodyMedium,
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.brandPrimary),
            ),
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),
        MlButton(
          label: 'Submit Reflection',
          onPressed: state.isSubmitting
              ? null
              : () {
                  if (_reflectionController.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please write at least a few words'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  ref
                      .read(challengeProvider(widget.challengeId).notifier)
                      .completeChallenge();
                },
          isLoading: state.isSubmitting,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildQuizChallenge(
      ChallengeModel challenge, ChallengeState state) {
    final question = challenge.content?['question'] as String? ??
        challenge.description;
    final optionsRaw = challenge.content?['options'];
    final options = optionsRaw is List
        ? optionsRaw.cast<String>()
        : <String>['Option A', 'Option B', 'Option C', 'Option D'];
    final correctIndex =
        challenge.content?['correct_index'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.sm),
        Text(question, style: AppTypography.h3),
        AppSpacing.vGap(AppSpacing.xl),

        ...List.generate(options.length, (i) {
          final isSelected = _selectedQuizAnswer == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedQuizAnswer = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    AppSpacing.hGap(AppSpacing.md),
                    Expanded(
                      child: Text(options[i], style: AppTypography.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        AppSpacing.vGap(AppSpacing.xl),
        MlButton(
          label: 'Submit Answer',
          onPressed: _selectedQuizAnswer == null || state.isSubmitting
              ? null
              : () {
                  if (_selectedQuizAnswer == correctIndex) {
                    ref
                        .read(challengeProvider(widget.challengeId).notifier)
                        .completeChallenge();
                  } else {
                    ref
                        .read(challengeProvider(widget.challengeId).notifier)
                        .failChallenge();
                  }
                },
          isLoading: state.isSubmitting,
          fullWidth: true,
        ),
      ],
    );
  }

  // ── COMPLETED PHASE ────────────────────────────────────────────────────────

  Widget _buildCompletedPhase(ChallengeState state) {
    final challenge = state.challenge!;
    final appName = _packageToName(state.packageName);

    return FadeTransition(
      opacity: _successFadeAnimation,
      child: SingleChildScrollView(
        padding: AppSpacing.screenPaddingFull,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppSpacing.vGap(AppSpacing.huge),

            // Success circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.recoveryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            AppSpacing.vGap(AppSpacing.xxl),

            Text('Challenge Complete!', style: AppTypography.h1),
            AppSpacing.vGap(AppSpacing.md),
            Text(
              'Excellent work. You earned your focus time.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.xl),

            // Reward badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.success, size: 20),
                  AppSpacing.hGap(AppSpacing.xs),
                  Text(
                    '+${challenge.rewardMinutes} minutes unlocked',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.vGap(AppSpacing.huge),

            MlButton(
              label: 'Return to $appName',
              onPressed: () => context.pop(),
              fullWidth: true,
              size: MlButtonSize.lg,
              leadingIcon: Icons.arrow_back_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ── FAILED PHASE ───────────────────────────────────────────────────────────

  Widget _buildFailedPhase(ChallengeState state) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingFull,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSpacing.vGap(AppSpacing.huge),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.error.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.error,
              size: 60,
            ),
          ),
          AppSpacing.vGap(AppSpacing.xxl),

          Text('Challenge Failed', style: AppTypography.h1),
          AppSpacing.vGap(AppSpacing.md),
          Text(
            'Don\'t worry — every attempt builds resilience. Try again?',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGap(AppSpacing.huge),

          MlButton(
            label: 'Try Again',
            onPressed: () {
              ref
                  .read(challengeProvider(widget.challengeId).notifier)
                  .retryChallenge();
            },
            fullWidth: true,
            size: MlButtonSize.lg,
          ),
          AppSpacing.vGap(AppSpacing.md),
          MlButton(
            label: 'Back to Lock Screen',
            onPressed: () => context.pop(),
            variant: MlButtonVariant.ghost,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ────────────────────────────────────────────────────────────

  Widget _buildLoadError(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingFull,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            AppSpacing.vGap(AppSpacing.md),
            Text('Failed to load challenge', style: AppTypography.h3),
            AppSpacing.vGap(AppSpacing.sm),
            Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
            AppSpacing.vGap(AppSpacing.lg),
            MlButton(
              label: 'Go Back',
              onPressed: () => context.pop(),
              variant: MlButtonVariant.secondary,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  // ── GIVE UP DIALOG ─────────────────────────────────────────────────────────

  void _confirmGiveUp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Give Up?', style: AppTypography.h3),
        content: Text(
          'You won\'t earn the unlock time. Are you sure?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Going',
                style: TextStyle(color: AppColors.brandPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(challengeProvider(widget.challengeId).notifier)
                  .failChallenge();
            },
            child:
                Text('Give Up', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  String _typeEmoji(String type) {
    return switch (type) {
      'breathing' => '💨',
      'reflection' => '🧘',
      'quiz' => '🧠',
      'habit' => '✅',
      'learning' => '📚',
      _ => '🎯',
    };
  }

  String _difficultyLabel(String difficulty) {
    return switch (difficulty) {
      'easy' => 'Easy',
      'medium' => 'Medium',
      'hard' => 'Hard',
      _ => difficulty,
    };
  }

  Color _difficultyColor(String difficulty) {
    return switch (difficulty) {
      'easy' => AppColors.success,
      'medium' => AppColors.warning,
      'hard' => AppColors.error,
      _ => AppColors.textTertiary,
    };
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  String _packageToName(String? packageName) {
    if (packageName == null || packageName.isEmpty) return 'App';
    final names = {
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.twitter.android': 'X (Twitter)',
      'com.facebook.katana': 'Facebook',
      'com.reddit.frontpage': 'Reddit',
    };
    return names[packageName] ?? packageName.split('.').last;
  }

  Widget _badge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            AppSpacing.hGap(AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int remainingSeconds;

  const _TimerDisplay({required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    final text = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: remainingSeconds <= 10
            ? AppColors.errorSurface
            : AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: remainingSeconds <= 10
              ? AppColors.error.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.statMedium.copyWith(
          fontSize: 22,
          color: remainingSeconds <= 10
              ? AppColors.error
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
