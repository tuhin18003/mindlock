import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/pro_gate.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../data/models/monitored_app_model.dart';
import '../providers/apps_provider.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/set_limit_sheet.dart';

class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appsProvider.notifier).loadApps();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MonitoredAppModel> _filtered(List<MonitoredAppModel> apps) {
    if (_searchQuery.isEmpty) return apps;
    return apps.where((app) {
      return app.appName.toLowerCase().contains(_searchQuery) ||
          app.packageName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openSetLimitSheet(BuildContext context, MonitoredAppModel app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetLimitSheet(app: app),
    );
  }

  void _showAddAppSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAppSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appsProvider);

    // Show error snackbar
    ref.listen<AppsState>(appsProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(appsProvider.notifier).clearError();
      }
    });

    final lockedApps = _filtered(state.apps.where((a) => a.isLocked).toList());
    final monitoredApps = _filtered(state.apps.where((a) => !a.isLocked).toList());

    return Scaffold(
      backgroundColor: AppColors.black,
      body: RefreshIndicator(
        onRefresh: () => ref.read(appsProvider.notifier).loadApps(),
        color: AppColors.brandPrimary,
        backgroundColor: AppColors.surfaceElevated,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, state),
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: state.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: CircularProgressIndicator(
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    )
                  : _buildContent(context, state, lockedApps, monitoredApps),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppSheet(context),
        backgroundColor: AppColors.brandPrimary,
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: Text('Add App', style: AppTypography.labelMedium),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppsState state) {
    return SliverAppBar(
      backgroundColor: AppColors.black,
      floating: true,
      pinned: false,
      elevation: 0,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Apps', style: AppTypography.h2),
            Text(
              '${state.apps.length} monitored',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMedium,
        decoration: const InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppsState state,
    List<MonitoredAppModel> lockedApps,
    List<MonitoredAppModel> monitoredApps,
  ) {
    if (state.apps.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        AppSpacing.vGap(AppSpacing.lg),
        // Locked apps section
        if (lockedApps.isNotEmpty) ...[
          _buildSectionHeader('LOCKED APPS', lockedApps.length, AppColors.error),
          AppSpacing.vGap(AppSpacing.md),
          ...lockedApps.map((app) => _buildAppTile(context, app, state, isLocked: true)),
          AppSpacing.vGap(AppSpacing.xl),
        ],
        // Monitored apps section
        _buildSectionHeader('MONITORED APPS', monitoredApps.length, AppColors.textTertiary),
        AppSpacing.vGap(AppSpacing.md),
        if (monitoredApps.isEmpty && lockedApps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No unlocked monitored apps',
                style: AppTypography.bodyMedium,
              ),
            ),
          )
        else
          ...monitoredApps.map((app) => _buildAppTile(context, app, state, isLocked: false)),
        const SizedBox(height: 100), // FAB clearance
      ]),
    );
  }

  Widget _buildSectionHeader(String label, int count, Color color) {
    return Row(
      children: [
        Text(label, style: AppTypography.overline.copyWith(color: color)),
        AppSpacing.hGap(AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(color: color, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAppTile(
    BuildContext context,
    MonitoredAppModel app,
    AppsState state, {
    required bool isLocked,
  }) {
    return GestureDetector(
      onLongPress: () => _openSetLimitSheet(context, app),
      child: AppListTile(
        app: app,
        todayUsageSeconds: state.todayUsageSeconds[app.packageName] ?? 0,
        onSettingsTap: () => _openSetLimitSheet(context, app),
        onLockToggle: (val) =>
            ref.read(appsProvider.notifier).toggleLock(app.packageName),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.phone_android_outlined,
              size: 36,
              color: AppColors.textTertiary,
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),
          Text(
            'No apps monitored yet',
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            'Add apps to start protecting your focus.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGap(AppSpacing.xl),
        ],
      ),
    );
  }
}

// --- Add App Sheet (inline, lightweight) ---
class _AddAppSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
          AppSpacing.vGap(AppSpacing.lg),
          Text('Add App to Monitor', style: AppTypography.h3),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            'Choose an app from your device to start monitoring and setting limits.',
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.vGap(AppSpacing.xl),
          // Pro gate: unlimited monitored apps
          ProGate(
            feature: MobileFeature.unlimitedMonitoredApps,
            upgradeLabel: 'Monitor More Apps',
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  AppSpacing.hGap(AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Free plan: up to 3 monitored apps. Upgrade Pro for unlimited.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_android, color: AppColors.info, size: 20),
                AppSpacing.hGap(AppSpacing.md),
                Expanded(
                  child: Text(
                    'App picker integration requires device usage access permission.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceHighlight,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              child: Text('Close', style: AppTypography.button),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
