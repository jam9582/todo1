import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _setupWidgetClickListener();
    }
  }

  void _setupWidgetClickListener() {
    // 앱이 이미 실행 중일 때 위젯 탭
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUrl);
    // 위젯 탭으로 앱이 처음 열린 경우
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleWidgetUrl(uri);
    }).catchError((_) {});
  }

  void _handleWidgetUrl(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != 'todo1' || uri.host != 'start') return;

    final timerProvider = context.read<TimerProvider>();
    if (timerProvider.isActive) return; // 이미 타이머 실행 중이면 무시

    final categoryIdStr = uri.queryParameters['categoryId'];
    final name = uri.queryParameters['name'] ?? '';
    final emoji = uri.queryParameters['emoji'] ?? '';
    final colorIndexStr = uri.queryParameters['colorIndex'];

    final categoryId = int.tryParse(categoryIdStr ?? '');
    final colorIndex = int.tryParse(colorIndexStr ?? '') ?? 0;

    if (categoryId != null && categoryId > 0 && name.isNotEmpty) {
      timerProvider.startWithCategory(
        categoryId: categoryId,
        categoryName: name,
        categoryEmoji: emoji,
        colorIndex: colorIndex,
      );
    } else {
      timerProvider.start();
    }
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    super.dispose();
  }

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

  Widget _buildMiniTimerButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _handleHeaderComplete(BuildContext context, TimerProvider timerProvider) {
    final minutes = timerProvider.complete();
    if (minutes <= 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.timerTooShort),
          backgroundColor: AppColors.snackbar,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    TimerBottomSheet.showForCategorySelection(context, minutes);
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
          Consumer<TimerProvider>(
            builder: (context, timerProvider, _) {
              // 알림 '완료' 액션 → 카테고리 선택 바텀시트 표시
              if (timerProvider.pendingComplete) {
                timerProvider.clearPendingComplete();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleHeaderComplete(context, timerProvider);
                });
              }

              if (!timerProvider.isActive) return const Spacer();
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniTimerButton(
                        icon: timerProvider.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: () {
                          if (timerProvider.isRunning) {
                            timerProvider.pause();
                          } else {
                            timerProvider.resume();
                          }
                        },
                      ),
                      _buildMiniTimerButton(
                        icon: Icons.close_rounded,
                        onTap: () => timerProvider.cancel(),
                      ),
                      _buildMiniTimerButton(
                        icon: Icons.check_rounded,
                        onTap: () => _handleHeaderComplete(context, timerProvider),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatElapsed(timerProvider.elapsed),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              );
            },
          ),
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
              onPressed: timerProvider.isActive
                  ? () {}
                  : () => context.read<TimerProvider>().start(),
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
