import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../utils/responsive.dart';
import '../../../utils/debounced_gesture_detector.dart';

class CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isWeekend;
  final String? emoji;
  final int? minutes; // 분 단위로 받음
  final int completedChecks;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isWeekend,
    this.emoji,
    this.minutes,
    this.completedChecks = 0,
    required this.onTap,
  });

  // 분을 H:MM 형식으로 변환
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = emoji != null && minutes != null && minutes! > 0;

    return DebouncedGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 날짜 숫자 (선택 시 컴팩트한 박스)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.textOnAccent
                      : (isWeekend ? AppColors.error : AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // 카테고리 정보 영역 (항상 공간 유지)
            SizedBox(
              height: 18,
              child: hasData
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji!,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 9),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatTime(minutes!),
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 8),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 2),
            // 체크박스 완료 개수
            SizedBox(
              height: 18,
              child: completedChecks > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.grey300.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_box_outlined,
                            size: Responsive.fontSize(context, 9),
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$completedChecks',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 8),
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
