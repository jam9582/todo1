import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
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
        top: AppTheme.spacingMd,
        bottom: 2,
      ),
      color: AppTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DebouncedIconButton(
            icon: AnimatedRotation(
              turns: isMenuOpen ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.menu),
            ),
            onPressed: onMenuPressed,
          ),
        ],
      ),
    );
  }
}
