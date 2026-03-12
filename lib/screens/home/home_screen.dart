import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import '../../services/widget_service.dart';
import 'widgets/timer_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  StreamSubscription? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isIOS) {
      _setupWidgetClickListener();
      _checkWidgetLaunchUrl(); // cold start: App Group에서 위젯 URL 읽기
    }
  }

  // iOS 위젯 카테고리 탭 URL을 App Group UserDefaults에서 읽어 타이머 시작
  Future<void> _checkWidgetLaunchUrl() async {
    final uri = await WidgetService.popWidgetLaunchUrl();
    if (uri != null) _handleWidgetUrl(uri);
  }

  // 앱이 포그라운드로 돌아올 때 위젯 URL 확인 (warm start)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      _checkWidgetLaunchUrl();
    }
  }

  void _setupWidgetClickListener() {
    // 앱이 이미 실행 중일 때 위젯 탭
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUrl);
    // 위젯 탭으로 앱이 처음 열린 경우
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleWidgetUrl(uri);
    }).catchError((e, s) { FirebaseCrashlytics.instance.recordError(e, s, fatal: false); });
  }

  void _handleWidgetUrl(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != 'tinylog' || uri.host != 'start') return;

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
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recordProvider = context.watch<RecordProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final isRestDay = recordProvider.isCurrentRestDay;
    final isSelecting = timerProvider.isSelecting;

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
                      // 선택 대기 중엔 카테고리 외 섹션 흐리게 + 터치 차단
                      IgnorePointer(
                        ignoring: isSelecting,
                        child: AnimatedOpacity(
                          opacity: isSelecting ? 0.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: const DailyMessageSection(),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grey200,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Stack(
                        children: [
                          Column(
                            children: [
                              // 카테고리 섹션: isSelecting 중에도 터치 활성
                              IgnorePointer(
                                ignoring: isRestDay,
                                child: const CategorySection(),
                              ),
                              // 체크박스 섹션: isSelecting 중 흐리게 + 터치 차단
                              IgnorePointer(
                                ignoring: isRestDay || isSelecting,
                                child: AnimatedOpacity(
                                  opacity: isSelecting ? 0.15 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: const CheckboxSection(),
                                ),
                              ),
                            ],
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
                      IgnorePointer(
                        ignoring: isSelecting,
                        child: AnimatedOpacity(
                          opacity: isSelecting ? 0.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: const CalendarSection(),
                        ),
                      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  void _handleHeaderComplete(BuildContext context, TimerProvider timerProvider) {
    final result = timerProvider.complete();
    final l10n = AppLocalizations.of(context)!;

    if (result.minutes <= 0) {
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

    final categoryId = result.categoryId;
    final categoryName = result.categoryName;
    if (categoryId != null && categoryName != null && categoryName.isNotEmpty) {
      // 카테고리 있음 → 자동 저장 + 스낵바
      context.read<RecordProvider>()
        ..updateTimeRecordForToday(categoryId, result.minutes)
        ..selectDate(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$categoryName에 ${result.minutes}분 추가되었어요'),
          backgroundColor: AppColors.snackbar,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // 카테고리 없음(위젯/알림에서 시작) → 기존 바텀시트
      TimerBottomSheet.showForCategorySelection(context, result.minutes);
    }
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
                    children: [
                      _buildMiniTimerButton(
                        icon: timerProvider.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: () {
                          if (timerProvider.isRunning) {
                            timerProvider.pause();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('시간 측정이 일시정지 되었습니다'),
                                backgroundColor: AppColors.snackbar,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            timerProvider.resume();
                          }
                        },
                      ),
                      _buildMiniTimerButton(
                        icon: Icons.close_rounded,
                        onTap: () {
                          timerProvider.cancel();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('시간 측정이 취소되었습니다'),
                              backgroundColor: AppColors.snackbar,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _buildMiniTimerButton(
                        icon: Icons.check_rounded,
                        onTap: () => _handleHeaderComplete(context, timerProvider),
                      ),
                      const SizedBox(width: 4),
                      if (timerProvider.categoryEmoji != null) ...[
                        Text(
                          timerProvider.categoryEmoji!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Flexible(
                        child: Text(
                          _formatElapsed(timerProvider.elapsed),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<TimerProvider>(
            builder: (context, timerProvider, _) => DebouncedIconButton(
              icon: Icon(
                timerProvider.isSelecting
                    ? Icons.close_rounded        // 선택 취소
                    : timerProvider.isActive
                        ? Icons.timer_rounded
                        : Icons.timer_outlined,
                color: (timerProvider.isSelecting || timerProvider.isActive)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              onPressed: timerProvider.isActive
                  ? () {}                        // 측정 중엔 타이머 버튼 무반응
                  : timerProvider.isSelecting
                      ? () => context.read<TimerProvider>().cancelSelecting()
                      : () => context.read<TimerProvider>().startSelecting(),
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
