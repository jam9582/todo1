import 'package:flutter/material.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../constants/colors.dart';
import '../../constants/app_theme.dart';
import '../../utils/debounced_gesture_detector.dart';
import '../../utils/snackbar_manager.dart';
import 'sections/header_section.dart';
import 'sections/daily_message_section.dart';
import 'sections/category_section.dart';
import 'sections/calendar_section.dart';
import 'widgets/category_edit_dialog.dart';

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

  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.bar_chart_rounded, label: '통계'),
    _MenuItem(icon: Icons.edit_rounded, label: '카테고리 편집'),
    _MenuItem(icon: Icons.workspace_premium_rounded, label: '광고 제거'),
    _MenuItem(icon: Icons.settings_rounded, label: '설정'),
  ];

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

  void _onMenuItemTap(String label) {
    _closeMenu();

    if (label == '카테고리 편집') {
      CategoryEditDialog.show(context);
    } else {
      SnackBarManager.showText(context, '$label 기능은 준비 중입니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        // 헤더 (오늘의 한마디 제목 + 햄버거 메뉴)
                        HeaderSection(
                          onMenuPressed: _toggleMenu,
                          isMenuOpen: _isMenuOpen,
                        ),

                        // 한마디 입력
                        const DailyMessageSection(),

                        // 카테고리 섹션 (4개 카테고리)
                        const CategorySection(),

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
                top: 56 + AppTheme.spacingLg + AppTheme.spacingSm, // Header 높이
                right: AppTheme.spacingMd,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _menuItems.asMap().entries.map((entry) {
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
                            onTap: () => _onMenuItemTap(item.label),
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
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});
}
