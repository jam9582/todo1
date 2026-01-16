import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../utils/debounced_gesture_detector.dart';

class CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isWeekend;
  final String? emoji;
  final double? hours;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isWeekend,
    this.emoji,
    this.hours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = emoji != null && hours != null;

    return DebouncedGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8), // 둥근 사각형
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: hasData ? 2 : 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? Colors.white
                        : (isWeekend ? Colors.red : Colors.black87),
                  ),
                ),
              ),
            ),
            if (hasData) ...[
              Flexible(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    emoji!,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hours!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      color: isToday ? Colors.white : Colors.black54,
                    ),
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
