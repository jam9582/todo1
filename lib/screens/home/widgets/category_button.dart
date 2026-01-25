import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../utils/debounced_gesture_detector.dart';

class CategoryButton extends StatelessWidget {
  final String emoji;
  final String name;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.emoji,
    required this.name,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DebouncedGestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, AppTheme.spacingXs),
        ),
        padding: EdgeInsets.symmetric(
          vertical: Responsive.spacing(context, AppTheme.spacingMd * 0.75),
          horizontal: Responsive.spacing(context, AppTheme.spacingXs),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 24),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, AppTheme.spacingXs)),
            Text(
              name,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeCaption),
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, AppTheme.spacingXs)),
            Text(
              time,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
