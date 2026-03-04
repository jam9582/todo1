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
  final bool isHighlighted; // 카테고리 선택 대기 중: 펄스 테두리
  final bool isDimmed;      // 다른 카테고리 측정 중: 흐리게
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.emoji,
    required this.name,
    required this.time,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
    this.isHighlighted = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _CategoryButtonContent(
      emoji: emoji,
      name: name,
      time: time,
      isSelected: isSelected,
      enabled: enabled,
    );

    if (isDimmed) {
      return AnimatedOpacity(
        opacity: 0.3,
        duration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    if (isHighlighted) {
      return _PulsingBorder(
        child: DebouncedGestureDetector(onTap: onTap, child: content),
      );
    }

    if (!enabled) return content;

    return DebouncedGestureDetector(onTap: onTap, child: content);
  }
}

class _CategoryButtonContent extends StatelessWidget {
  final String emoji;
  final String name;
  final String time;
  final bool isSelected;
  final bool enabled;

  const _CategoryButtonContent({
    required this.emoji,
    required this.name,
    required this.time,
    required this.isSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
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
  }
}

/// 펄스 테두리 애니메이션 — 카테고리 선택 대기 중
class _PulsingBorder extends StatefulWidget {
  final Widget child;

  const _PulsingBorder({required this.child});

  @override
  State<_PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<_PulsingBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd + 3),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: _opacity.value),
            width: 2,
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
