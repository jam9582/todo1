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
  final bool enabled;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.emoji,
    required this.name,
    required this.time,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context, AppTheme.spacingXs),
      ),
      padding: EdgeInsets.symmetric(
        vertical: Responsive.spacing(context, AppTheme.spacingSm),
        horizontal: Responsive.spacing(context, AppTheme.spacingXs),
      ),
      decoration: BoxDecoration(
        color: enabled
            ? (isSelected ? AppColors.accent : AppColors.grey100)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 2)),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeCaption),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 2)),
            Text(
              time,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled) return container;

    return DebouncedGestureDetector(
      onTap: onTap,
      child: container,
    );
  }
}
