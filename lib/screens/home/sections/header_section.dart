import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../utils/debounced_gesture_detector.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: AppTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          Text(
            '오늘의 한마디',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, AppTheme.fontSizeH3),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          DebouncedIconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: 햄버거 메뉴 기능 (나중에 구현)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메뉴 기능은 나중에 구현 예정')),
              );
            },
          ),
        ],
      ),
    );
  }
}
