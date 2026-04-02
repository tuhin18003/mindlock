import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/history_models.dart';
import '../../data/remote/history_remote_datasource.dart';

class HistoryState {
  final List<ActivityEvent> events;
  final HistoryStats? stats;
  final bool isLoading;
  final bool hasMore;
  final String? nextBefore;
  final String? error;

  const HistoryState({
    this.events = const [],
    this.stats,
    this.isLoading = false,
    this.hasMore = true,
    this.nextBefore,
    this.error,
  });

  HistoryState copyWith({
    List<ActivityEvent>? events,
    HistoryStats? stats,
    bool? isLoading,
    bool? hasMore,
    String? nextBefore,
    String? error,
    bool clearError = false,
    bool clearNextBefore = false,
  }) {
    return HistoryState(
      events: events ?? this.events,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      nextBefore: clearNextBefore ? null : (nextBefore ?? this.nextBefore),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRemoteDatasource? _datasource;
  static const int _pageSize = 20;

  HistoryNotifier({HistoryRemoteDatasource? datasource})
      : _datasource = datasource,
        super(const HistoryState());

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_datasource != null) {
        final results = await Future.wait([
          _datasource!.getActivity(limit: _pageSize),
          _datasource!.getStats(),
        ]);
        final events = results[0] as List<ActivityEvent>;
        final stats = results[1] as HistoryStats;
        state = state.copyWith(
          events: events,
          stats: stats,
          isLoading: false,
          hasMore: events.length >= _pageSize,
          nextBefore: events.isNotEmpty ? events.last.occurredAt : null,
        );
      } else {
        // Mock data for development
        state = state.copyWith(
          events: _mockEvents(),
          stats: _mockStats(),
          isLoading: false,
          hasMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.nextBefore == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final more = await _datasource?.getActivity(
            limit: _pageSize,
            before: state.nextBefore,
          ) ??
          [];
      state = state.copyWith(
        events: [...state.events, ...more],
        isLoading: false,
        hasMore: more.length >= _pageSize,
        nextBefore: more.isNotEmpty ? more.last.occurredAt : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const HistoryState();
    await loadInitial();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // --- Mock data ---
  List<ActivityEvent> _mockEvents() {
    final now = DateTime.now();
    return [
      ActivityEvent(
        eventType: 'lock',
        eventId: '1',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        occurredAt: now.subtract(const Duration(minutes: 15)).toIso8601String(),
      ),
      ActivityEvent(
        eventType: 'unlock',
        eventId: '2',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        method: 'challenge',
        rewardMinutes: 10,
        occurredAt: now.subtract(const Duration(minutes: 12)).toIso8601String(),
      ),
      ActivityEvent(
        eventType: 'challenge',
        eventId: '3',
        result: 'passed',
        occurredAt: now.subtract(const Duration(minutes: 12)).toIso8601String(),
      ),
      ActivityEvent(
        eventType: 'focus',
        eventId: '4',
        rewardMinutes: 25,
        occurredAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      ActivityEvent(
        eventType: 'lock',
        eventId: '5',
        packageName: 'com.twitter.android',
        appName: 'Twitter / X',
        occurredAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
      ),
      ActivityEvent(
        eventType: 'emergency',
        eventId: '6',
        packageName: 'com.zhiliaoapp.musically',
        occurredAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
      ),
    ];
  }

  HistoryStats _mockStats() {
    return const HistoryStats(
      periodDays: 30,
      totalLocks: 47,
      totalChallenges: 32,
      totalEmergencyUnlocks: 3,
      totalRecoveredMinutes: 420,
      totalFocusMinutes: 180,
      challengeSuccessRate: 0.84,
      mostLockedApp: 'Instagram',
    );
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});

final historyStatsProvider = FutureProvider<HistoryStats>((ref) async {
  final notifier = ref.watch(historyProvider.notifier);
  // Attempt to load stats directly if datasource available
  // Falls back to state stats already loaded
  final state = ref.watch(historyProvider);
  if (state.stats != null) return state.stats!;
  return HistoryStats.empty();
});
