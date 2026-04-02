import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/challenge_model.dart';
import '../../data/remote/challenges_remote_datasource.dart';

const _uuid = Uuid();

enum ChallengePhase { intro, active, completed, failed }

class ChallengeState {
  final ChallengeModel? challenge;
  final String? packageName;
  final ChallengePhase phase;
  final int remainingSeconds;
  final bool isSubmitting;
  final String? error;

  const ChallengeState({
    this.challenge,
    this.packageName,
    this.phase = ChallengePhase.intro,
    this.remainingSeconds = 0,
    this.isSubmitting = false,
    this.error,
  });

  ChallengeState copyWith({
    ChallengeModel? challenge,
    String? packageName,
    ChallengePhase? phase,
    int? remainingSeconds,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ChallengeState(
      challenge: challenge ?? this.challenge,
      packageName: packageName ?? this.packageName,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final ChallengesRemoteDatasource _datasource;
  Timer? _timer;

  ChallengeNotifier(this._datasource) : super(const ChallengeState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadChallenge(int id, String? packageName) async {
    state = state.copyWith(
      phase: ChallengePhase.intro,
      packageName: packageName,
      clearError: true,
    );
    try {
      final challenge = await _datasource.getChallenge(id);
      state = state.copyWith(
        challenge: challenge,
        remainingSeconds: challenge.durationSeconds,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load challenge: $e');
    }
  }

  void startChallenge() {
    if (state.challenge == null) return;
    state = state.copyWith(
      phase: ChallengePhase.active,
      remainingSeconds: state.challenge!.durationSeconds,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tickTimer());
  }

  void tickTimer() {
    if (state.phase != ChallengePhase.active) {
      _timer?.cancel();
      return;
    }
    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _timer?.cancel();
      state = state.copyWith(remainingSeconds: 0);
      // Auto-complete timed challenge types on timer expiry
      final type = state.challenge?.type ?? '';
      if (type == 'breathing' || type == 'mindfulness') {
        completeChallenge();
      }
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  Future<void> completeChallenge() async {
    _timer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _submitResult('completed');
    } catch (_) {
      // Offline-first — show completed locally even if sync fails
    } finally {
      state = state.copyWith(phase: ChallengePhase.completed, isSubmitting: false);
    }
  }

  Future<void> failChallenge() async {
    _timer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _submitResult('failed');
    } catch (_) {
      // Best-effort
    } finally {
      state = state.copyWith(phase: ChallengePhase.failed, isSubmitting: false);
    }
  }

  void retryChallenge() {
    _timer?.cancel();
    state = state.copyWith(
      phase: ChallengePhase.intro,
      remainingSeconds: state.challenge?.durationSeconds ?? 0,
      clearError: true,
    );
  }

  Future<void> _submitResult(String result) async {
    final challenge = state.challenge;
    if (challenge == null) return;

    await _datasource.submitCompletion(
      localEventId: _uuid.v4(),
      challengeId: challenge.id,
      result: result,
      packageName: state.packageName,
      rewardGrantedMinutes: result == 'completed' ? challenge.rewardMinutes : 0,
    );
  }
}

final _challengesRemoteDatasourceProvider = Provider<ChallengesRemoteDatasource>((ref) {
  return ChallengesRemoteDatasource(ref.watch(dioProvider));
});

final challengeProvider = StateNotifierProvider.family<
    ChallengeNotifier, ChallengeState, String>(
  (ref, challengeId) => ChallengeNotifier(ref.watch(_challengesRemoteDatasourceProvider)),
);
