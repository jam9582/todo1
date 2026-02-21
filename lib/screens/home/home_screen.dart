import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../constants/colors.dart';
import '../../constants/app_theme.dart';
import '../../utils/debounced_gesture_detector.dart';
import '../../utils/snackbar_manager.dart';
import 'sections/daily_message_section.dart';
import 'sections/category_section.dart';
import 'sections/checkbox_section.dart';
import 'sections/calendar_section.dart';
import 'widgets/category_edit_dialog.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/purchase_provider.dart';
import '../../l10n/app_localizations.dart';

enum _MenuAction { statistics, categoryEdit, removeAds, settings }

class _MenuItem {
  final IconData icon;
  final String label;
  final _MenuAction action;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.action,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<_MenuItem> _buildMenuItems(AppLocalizations l10n) => [
        _MenuItem(icon: Icons.bar_chart_rounded, label: l10n.menuStatistics, action: _MenuAction.statistics),
        _MenuItem(icon: Icons.edit_rounded, label: l10n.menuCategoryEdit, action: _MenuAction.categoryEdit),
        _MenuItem(icon: Icons.workspace_premium_rounded, label: l10n.menuRemoveAds, action: _MenuAction.removeAds),
        _MenuItem(icon: Icons.settings_rounded, label: l10n.settingsTitle, action: _MenuAction.settings),
      ];

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _onMenuItemTap(_MenuAction action) {
    _closeMenu();

    switch (action) {
      case _MenuAction.statistics:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsScreen()),
        );
      case _MenuAction.categoryEdit:
        CategoryEditDialog.show(context);
      case _MenuAction.removeAds:
        _showPaywall();
      case _MenuAction.settings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
    }
  }

  Future<void> _showPaywall() async {
    final l10n = AppLocalizations.of(context)!;
    final purchaseProvider = context.read<PurchaseProvider>();

    if (purchaseProvider.isAdRemoved) {
      SnackBarManager.showText(context, l10n.msgAdsAlreadyRemoved);
      return;
    }

    final result = await RevenueCatUI.presentPaywallIfNeeded('remove_ads');

    if (!mounted) return;

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await purchaseProvider.refresh();
      if (!mounted) return;
      SnackBarManager.showText(context, l10n.msgAdsRemoved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final menuItems = _buildMenuItems(l10n);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
          children: [
            // 메인 콘텐츠
            Column(
              children: [
                // 스크롤 가능한 컨텐츠
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 한마디 입력 (오늘의 한마디 라벨 포함)
                        const DailyMessageSection(),
                        const Divider(height: 1, thickness: 1, color: AppColors.grey200, indent: 16, endIndent: 16),

                        // 카테고리 섹션 (4개 카테고리)
                        const CategorySection(),

                        // 체크박스 섹션
                        const CheckboxSection(),
                        const Divider(height: 1, thickness: 1, color: AppColors.grey200, indent: 16, endIndent: 16),

                        // 달력
                        const CalendarSection(),
                      ],
                    ),
                  ),
                ),

                // 광고 영역
                const AdBannerWidget(),
              ],
            ),

            // 햄버거 메뉴 버튼
            Positioned(
              top: AppTheme.spacingMd,
              right: AppTheme.spacingMd,
              child: DebouncedIconButton(
                icon: const Icon(Icons.menu),
                onPressed: _toggleMenu,
              ),
            ),

            // 오버레이 메뉴
            if (_isMenuOpen) ...[
              // 배경 탭하면 메뉴 닫기
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // 메뉴 아이콘들
              Positioned(
                top: AppTheme.spacingMd + 40, // 햄버거 버튼 아래
                right: AppTheme.spacingMd,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: menuItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 100 + (index * 50)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DebouncedGestureDetector(
                            onTap: () => _onMenuItemTap(item.action),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: 24,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
