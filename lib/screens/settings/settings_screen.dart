import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final categories = context.watch<CategoryProvider>().categories;

    // 고정 카테고리 ID가 더 이상 존재하지 않으면 초기화
    if (settings.displayMode == CalendarDisplayMode.fixedCategory &&
        settings.fixedCategoryId != null &&
        !categories.any((c) => c.id == settings.fixedCategoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SettingsProvider>().setFixedCategoryId(null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        children: [
          // ─── 달력 설정 ───────────────────────────────────────────
          _SectionHeader(title: l10n.sectionCalendar),
          _SettingsCard(
            children: [
              _SegmentedRow<CalendarStartDay>(
                label: l10n.labelWeekStart,
                value: settings.startDay,
                segments: [
                  ButtonSegment(value: CalendarStartDay.sunday, label: Text(l10n.sunday)),
                  ButtonSegment(value: CalendarStartDay.monday, label: Text(l10n.monday)),
                ],
                onChanged: (v) => context.read<SettingsProvider>().setStartDay(v),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ─── 달력 표시 설정 ──────────────────────────────────────
          _SectionHeader(title: l10n.sectionCalendarDisplay),
          _SettingsCard(
            children: [
              _SegmentedRow<CalendarDisplayMode>(
                label: l10n.labelCategoryDisplay,
                value: settings.displayMode,
                segments: [
                  ButtonSegment(
                    value: CalendarDisplayMode.topCategory,
                    label: Text(l10n.displayModeTopCategory),
                  ),
                  ButtonSegment(
                    value: CalendarDisplayMode.fixedCategory,
                    label: Text(l10n.displayModeFixedCategory),
                  ),
                ],
                onChanged: (v) => context.read<SettingsProvider>().setDisplayMode(v),
              ),
              if (settings.displayMode == CalendarDisplayMode.fixedCategory) ...[
                _Divider(),
                _DropdownRow(
                  label: l10n.labelDisplayCategory,
                  hint: l10n.dropdownHint,
                  value: settings.fixedCategoryId,
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.emoji}  ${c.name}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setFixedCategoryId(v),
                ),
              ],
              _Divider(),
              _SwitchRow(
                label: l10n.labelShowActivityTime,
                value: settings.showActivityTime,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setShowActivityTime(v),
              ),
              _Divider(),
              _SwitchRow(
                label: l10n.labelShowCheckCount,
                value: settings.showCheckCount,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setShowCheckCount(v),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ─── 알림 ────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionNotification),
          _SettingsCard(
            children: [
              _SwitchRow(
                label: l10n.labelDailyNotif,
                value: settings.notifEnabled,
                onChanged: (v) => _setNotifEnabled(context, v, l10n),
              ),
              if (settings.notifEnabled) ...[
                _Divider(),
                _TimeRow(
                  label: l10n.labelNotifTime,
                  hour: settings.notifHour,
                  minute: settings.notifMinute,
                  onTap: () => _pickTime(context, settings, l10n),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ─── 언어 ────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionLanguage),
          _SettingsCard(
            children: [
              _SegmentedRow<String>(
                label: l10n.labelLanguage,
                value: settings.language,
                segments: [
                  ButtonSegment(value: 'system', label: Text(l10n.langSystem)),
                  ButtonSegment(value: 'ko', label: Text(l10n.langKorean)),
                  ButtonSegment(value: 'en', label: Text(l10n.langEnglish)),
                ],
                onChanged: (v) =>
                    context.read<SettingsProvider>().setLanguage(v),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ─── 구매 관리 ────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionPurchase),
          _SettingsCard(
            children: [
              _TapRow(
                label: l10n.labelRestorePurchase,
                onTap: () => _restorePurchases(context, l10n),
              ),
              _Divider(),
              _TapRow(
                label: l10n.labelPurchaseHistory,
                onTap: () => RevenueCatUI.presentCustomerCenter(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ─── 앱 정보 ─────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionAppInfo),
          _SettingsCard(
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.hasData
                      ? snapshot.data!.version
                      : '-';
                  return _InfoRow(label: l10n.labelVersion, value: version);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  Future<void> _setNotifEnabled(
      BuildContext context, bool v, AppLocalizations l10n) async {
    await context.read<SettingsProvider>().setNotifEnabled(
          v,
          notifTitle: l10n.notifTitle,
          notifBody: l10n.notifBody,
        );
  }

  Future<void> _pickTime(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notifHour,
        minute: settings.notifMinute,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      await context.read<SettingsProvider>().setNotifTime(
            picked.hour,
            picked.minute,
            notifTitle: l10n.notifTitle,
            notifBody: l10n.notifBody,
          );
    }
  }

  Future<void> _restorePurchases(
      BuildContext context, AppLocalizations l10n) async {
    final purchaseProvider = context.read<PurchaseProvider>();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isAdRemoved =
          customerInfo.entitlements.active.containsKey('remove_ads');
      await purchaseProvider.refresh();
      if (context.mounted) {
        final msg = isAdRemoved
            ? l10n.msgPurchaseRestored
            : l10n.msgNoPurchaseToRestore;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgRestoreFailed)),
        );
      }
    }
  }
}

// ─── 섹션 헤더 ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppTheme.spacingSm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeCaption,
          fontWeight: FontWeight.w600,
          color: AppColors.grey500,
        ),
      ),
    );
  }
}

// ─── 설정 카드 컨테이너 ───────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ─── 구분선 ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderLight,
      indent: 16,
      endIndent: 16,
    );
  }
}

// ─── 스위치 행 ────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fontSizeBody),
          ),
          Switch(
            value: value,
            activeColor: AppColors.textOnAccent,
            activeTrackColor: AppColors.grey500,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── 세그먼트 행 ──────────────────────────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fontSizeBody),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SegmentedButton<T>(
            segments: segments,
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surface,
              selectedBackgroundColor: AppColors.accent,
              selectedForegroundColor: AppColors.textOnAccent,
              foregroundColor: AppColors.textPrimary,
              textStyle: const TextStyle(fontSize: AppTheme.fontSizeCaption),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 드롭다운 행 ──────────────────────────────────────────────────────────────

class _DropdownRow extends StatelessWidget {
  final String label;
  final String hint;
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fontSizeBody),
          ),
          DropdownButton<int>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppColors.textPrimary,
            ),
            hint: Text(
              hint,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 시간 행 ─────────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: AppTheme.fontSizeBody),
            ),
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 탭 행 ───────────────────────────────────────────────────────────────────

class _TapRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TapRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: AppTheme.fontSizeBody),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 정보 행 ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fontSizeBody),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}
