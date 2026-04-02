import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/pro_gate.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../data/models/history_models.dart';
import '../providers/history_provider.dart';
import '../widgets/activity_event_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);

    ref.listen<HistoryState>(historyProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(historyProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.black,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(context, state),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () => ref.read(historyProvider.notifier).refresh(),
          color: AppColors.brandPrimary,
          backgroundColor: AppColors.surfaceElevated,
          child: state.isLoading && state.events.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brandPrimary),
                )
              : _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HistoryState state) {
    return SliverAppBar(
      backgroundColor: AppColors.black,
      pinned: true,
      floating: false,
      expandedHeight: state.stats != null ? 220 : 80,
      elevation: 0,
      title: Text('History', style: AppTypography.h2),
      flexibleSpace: FlexibleSpaceBar(
        background: state.stats != null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                child: _buildStatsCards(state.stats!),
              )
            : null,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.brandPrimary,
        indicatorWeight: 2,
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
        tabs: const [
          Tab(text: 'Activity'),
          Tab(text: 'Locks'),
          Tab(text: 'Challenges'),
        ],
      ),
    );
  }

  Widget _buildStatsCards(HistoryStats stats) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatChip(
                'Locks',
                '${stats.totalLocks}',
                Icons.lock_outline_rounded,
                AppColors.brandPrimary,
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            Expanded(
              child: _buildStatChip(
                'Challenges',
                '${stats.totalChallenges}',
                Icons.emoji_events_outlined,
                AppColors.focusSession,
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            Expanded(
              child: _buildStatChip(
                'Recovered',
                '${stats.totalRecoveredMinutes}m',
                Icons.bolt_rounded,
                AppColors.recoveredTime,
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            Expanded(
              child: _buildStatChip(
                'Focus',
                '${stats.totalFocusMinutes}m',
                Icons.timer_outlined,
                AppColors.focusSession,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          AppSpacing.vGap(AppSpacing.xs),
          Text(value, style: AppTypography.statMedium.copyWith(fontSize: 18)),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HistoryState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildActivityTab(state),
        _buildLocksTab(state),
        _buildChallengesTab(state),
      ],
    );
  }

  Widget _buildActivityTab(HistoryState state) {
    if (state.events.isEmpty && !state.isLoading) {
      return _buildEmptyState('No activity recorded yet');
    }

    // Group events by date
    final grouped = _groupByDate(state.events);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: grouped.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == grouped.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.brandPrimary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final entry = grouped[index];
        return _buildDateGroup(entry.key, entry.value);
      },
    );
  }

  Widget _buildLocksTab(HistoryState state) {
    final locks = state.events
        .where((e) => e.eventType == 'lock' || e.eventType == 'unlock')
        .toList();

    if (locks.isEmpty) {
      return _buildEmptyState('No lock events yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: locks.length,
      itemBuilder: (context, index) => ActivityEventTile(event: locks[index]),
    );
  }

  Widget _buildChallengesTab(HistoryState state) {
    final challenges =
        state.events.where((e) => e.eventType == 'challenge').toList();

    if (challenges.isEmpty) {
      return _buildEmptyState('No challenges yet');
    }

    // Summary row
    final passed = challenges.where((e) => e.result == 'passed').length;
    final total = challenges.length;
    final rate = total > 0 ? (passed / total * 100).toStringAsFixed(0) : '0';

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: challenges.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                  AppSpacing.hGap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$rate% success rate',
                          style: AppTypography.h3.copyWith(color: Colors.white),
                        ),
                        Text(
                          '$passed passed of $total challenges',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
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
        return ActivityEventTile(event: challenges[index - 1]);
      },
    );
  }

  List<MapEntry<String, List<ActivityEvent>>> _groupByDate(
      List<ActivityEvent> events) {
    final map = <String, List<ActivityEvent>>{};
    for (final event in events) {
      final dateKey = _parseDateLabel(event.occurredAt);
      map.putIfAbsent(dateKey, () => []).add(event);
    }
    return map.entries.toList();
  }

  String _parseDateLabel(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDay = DateTime(dt.year, dt.month, dt.day);

      if (eventDay == today) return 'Today';
      if (eventDay == today.subtract(const Duration(days: 1))) return 'Yesterday';

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return 'Unknown Date';
    }
  }

  Widget _buildDateGroup(String dateLabel, List<ActivityEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(dateLabel.toUpperCase(), style: AppTypography.overline),
        ),
        ...events.map((e) => ActivityEventTile(event: e)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.borderRadiusXl,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: AppColors.textTertiary,
              ),
            ),
            AppSpacing.vGap(AppSpacing.xl),
            Text(
              message,
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              'Your activity will appear here once you start using MindLock.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
