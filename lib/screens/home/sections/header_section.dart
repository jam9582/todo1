import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../utils/debounced_gesture_detector.dart';

class HeaderSection extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final bool isMenuOpen;

  const HeaderSection({
    super.key,
    required this.onMenuPressed,
    required this.isMenuOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingLg,
        bottom: AppTheme.spacingSm,
      ),
      color: AppTheme.backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              '오늘의 한마디',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeH3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: DebouncedIconButton(
              icon: AnimatedRotation(
                turns: isMenuOpen ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.menu),
              ),
              onPressed: onMenuPressed,
            ),
          ),
        ],
      ),
    );
  }
}
