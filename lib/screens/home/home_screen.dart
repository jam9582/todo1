import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../constants/colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/record_provider.dart';
import 'sections/daily_message_section.dart';
import 'sections/category_section.dart';
import 'sections/checkbox_section.dart';
import 'sections/calendar_section.dart';
import 'widgets/category_edit_dialog.dart';
import '../../utils/debounced_gesture_detector.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/timer_provider.dart';
import 'widgets/timer_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recordProvider = context.watch<RecordProvider>();
    final isRestDay = recordProvider.isCurrentRestDay;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const DailyMessageSection(),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grey200,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Stack(
                        children: [
                          IgnorePointer(
                            ignoring: isRestDay,
                            child: const Column(
                              children: [
                                CategorySection(),
                                CheckboxSection(),
                              ],
                            ),
                          ),
                          if (isRestDay)
                            Positioned.fill(
                              child: Container(
                                color: AppColors.background.withValues(alpha: 0.88),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.restDayOverlay,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grey200,
                        indent: 16,
                        endIndent: 16,
                      ),
                      const CalendarSection(),
                    ],
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingSm,
        top: 6,
        bottom: 2,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          const Spacer(),
          Consumer<TimerProvider>(
            builder: (context, timerProvider, _) => DebouncedIconButton(
              icon: Icon(
                timerProvider.isActive
                    ? Icons.timer_rounded
                    : Icons.timer_outlined,
                color: timerProvider.isActive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              onPressed: () => TimerBottomSheet.show(context),
            ),
          ),
          DebouncedIconButton(
            icon: const Icon(Icons.edit_rounded),
            color: AppColors.textSecondary,
            onPressed: () => CategoryEditDialog.show(context),
          ),
          DebouncedIconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          DebouncedIconButton(
            icon: const Icon(Icons.settings_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
