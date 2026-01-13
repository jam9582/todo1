import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFFF9966) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? Colors.white
                      : (isWeekend ? Colors.red : Colors.black87),
                ),
              ),
              if (emoji != null && hours != null) ...[
                const SizedBox(height: 1),
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  hours!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 8,
                    color: isToday ? Colors.white : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
