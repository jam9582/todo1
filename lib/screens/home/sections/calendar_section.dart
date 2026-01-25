import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/record_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../widgets/calendar_day_cell.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final selectedDate = recordProvider.selectedDate;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // 월 네비게이션
          _buildMonthNavigation(context, selectedDate),
          SizedBox(height: AppTheme.spacingMd),

          // 요일 헤더
          _buildWeekdayHeader(context),
          SizedBox(height: AppTheme.spacingSm),

          // 달력 그리드
          _buildCalendarGrid(context, selectedDate),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context, DateTime date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prevMonth = DateTime(date.year, date.month - 1, 1);
            context.read<RecordProvider>().selectDate(prevMonth);
          },
        ),
        Text(
          '${date.year}년 ${date.month}월 ${date.day}일',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final nextMonth = DateTime(date.year, date.month + 1, 1);
            context.read<RecordProvider>().selectDate(nextMonth);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        final isWeekend = day == 'Sun' || day == 'Sat';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeCaption),
                fontWeight: FontWeight.w600,
                color: isWeekend ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sun, 1 = Mon, ...

    final cells = <Widget>[];

    // 빈 셀 추가 (이전 달)
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // 날짜 셀 추가
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isToday = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

      cells.add(
        CalendarDayCell(
          day: day,
          isToday: isToday,
          isWeekend: isWeekend,
          // TODO: 실제 데이터에서 카테고리별 시간 가져오기
          onTap: () {
            final newDate = DateTime(selectedDate.year, selectedDate.month, day);
            context.read<RecordProvider>().selectDate(newDate);
          },
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9, // 세로 여유 공간 확보
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}
