import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ml_button.dart';
import '../../../../shared/widgets/pro_gate.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../data/models/monitored_app_model.dart';
import '../providers/apps_provider.dart';

class SetLimitSheet extends ConsumerStatefulWidget {
  final MonitoredAppModel app;

  const SetLimitSheet({super.key, required this.app});

  @override
  ConsumerState<SetLimitSheet> createState() => _SetLimitSheetState();
}

class _SetLimitSheetState extends ConsumerState<SetLimitSheet> {
  int? _selectedPreset; // minutes
  bool _useCustom = false;
  bool _useDifferentWeekends = false;
  final _customController = TextEditingController();
  final _weekdayController = TextEditingController();
  final _weekendController = TextEditingController();
  bool _isSaving = false;

  static const List<int> _presets = [30, 60, 120, 180];

  @override
  void initState() {
    super.initState();
    final existing = widget.app.dailyLimitMinutes;
    if (existing != null) {
      if (_presets.contains(existing)) {
        _selectedPreset = existing;
      } else {
        _useCustom = true;
        _customController.text = '$existing';
      }
    }
    if (widget.app.weekdayLimitMinutes != null || widget.app.weekendLimitMinutes != null) {
      _useDifferentWeekends = true;
      _weekdayController.text = '${widget.app.weekdayLimitMinutes ?? widget.app.dailyLimitMinutes ?? ''}';
      _weekendController.text = '${widget.app.weekendLimitMinutes ?? widget.app.dailyLimitMinutes ?? ''}';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _weekdayController.dispose();
    _weekendController.dispose();
    super.dispose();
  }

  int? get _resolvedDailyLimit {
    if (_useCustom) {
      return int.tryParse(_customController.text.trim());
    }
    return _selectedPreset;
  }

  String _formatPreset(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  Future<void> _save() async {
    final limit = _resolvedDailyLimit;
    if (limit == null || limit <= 0) return;

    setState(() => _isSaving = true);
    try {
      int? weekdayLimit;
      int? weekendLimit;
      if (_useDifferentWeekends) {
        weekdayLimit = int.tryParse(_weekdayController.text.trim());
        weekendLimit = int.tryParse(_weekendController.text.trim());
      }
      await ref.read(appsProvider.notifier).setLimit(
            widget.app.packageName,
            limit,
            weekdayLimitMinutes: weekdayLimit,
            weekendLimitMinutes: weekendLimit,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(appsProvider.notifier).removeLimit(widget.app.packageName);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Center(
                    child: Text(
                      widget.app.appName.isNotEmpty
                          ? widget.app.appName[0].toUpperCase()
                          : '?',
                      style: AppTypography.h3.copyWith(color: AppColors.brandPrimary),
                    ),
                  ),
                ),
                AppSpacing.hGap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Daily Limit', style: AppTypography.h3),
                      Text(widget.app.appName, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGap(AppSpacing.xl),
            Text('QUICK PRESETS', style: AppTypography.overline),
            AppSpacing.vGap(AppSpacing.md),
            // Preset chips
            Row(
              children: _presets.map((preset) {
                final isSelected = !_useCustom && _selectedPreset == preset;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset;
                        _useCustom = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.surfaceHighlight,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatPreset(preset),
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.vGap(AppSpacing.md),
            // Custom input toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _useCustom = true;
                  _selectedPreset = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _useCustom ? AppColors.brandPrimary.withOpacity(0.1) : AppColors.surfaceHighlight,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: _useCustom ? AppColors.brandPrimary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: _useCustom ? AppColors.brandPrimary : AppColors.textSecondary,
                    ),
                    AppSpacing.hGap(AppSpacing.sm),
                    Text(
                      'Custom limit',
                      style: AppTypography.labelMedium.copyWith(
                        color: _useCustom ? AppColors.brandPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_useCustom)
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _customController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: AppTypography.labelMedium,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'min',
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          autofocus: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AppSpacing.vGap(AppSpacing.xl),
            // Weekday / Weekend toggle (Pro-gated)
            ProGate(
              feature: MobileFeature.customLimits,
              upgradeLabel: 'Weekday/Weekend Limits',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Different Weekend Limit',
                              style: AppTypography.labelMedium,
                            ),
                            Text(
                              'Set separate limits for weekdays and weekends',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useDifferentWeekends,
                        onChanged: (val) {
                          setState(() => _useDifferentWeekends = val);
                        },
                        activeColor: AppColors.brandPrimary,
                        inactiveTrackColor: AppColors.border,
                      ),
                    ],
                  ),
                  if (_useDifferentWeekends) ...[
                    AppSpacing.vGap(AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLimitField('Weekdays (min)', _weekdayController),
                        ),
                        AppSpacing.hGap(AppSpacing.md),
                        Expanded(
                          child: _buildLimitField('Weekends (min)', _weekendController),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vGap(AppSpacing.xl),
            // Action buttons
            MlButton(
              label: 'Set Limit',
              onPressed: _resolvedDailyLimit != null ? _save : null,
              isLoading: _isSaving,
              leadingIcon: Icons.timer_outlined,
            ),
            AppSpacing.vGap(AppSpacing.sm),
            if (widget.app.dailyLimitMinutes != null)
              MlButton(
                label: 'Remove Limit',
                onPressed: _isSaving ? null : _remove,
                variant: MlButtonVariant.ghost,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        AppSpacing.vGap(AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Minutes',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceHighlight,
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
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
