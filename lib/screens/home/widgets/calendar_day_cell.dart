import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 셀 크기에 맞춰 동적으로 계산
        final cellSize = constraints.maxWidth;
        final hasData = emoji != null && hours != null;

        // 데이터 유무에 따라 폰트 크기 조정
        final dayFontSize = hasData ? cellSize * 0.28 : cellSize * 0.35;
        final emojiFontSize = cellSize * 0.22;
        final hoursFontSize = cellSize * 0.18;
        final spacing = cellSize * 0.02;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.all(cellSize * 0.04),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: cellSize * 0.9,
                height: cellSize * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: dayFontSize,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? Colors.white
                            : (isWeekend ? Colors.red : Colors.black87),
                      ),
                    ),
                    if (hasData) ...[
                      SizedBox(height: spacing),
                      Text(
                        emoji!,
                        style: TextStyle(fontSize: emojiFontSize),
                      ),
                      Text(
                        hours!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: hoursFontSize,
                          color: isToday ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
