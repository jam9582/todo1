import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/record_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../widgets/calendar_day_cell.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final selectedDate = recordProvider.selectedDate;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingSm,
        bottom: AppTheme.spacingMd,
      ),
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // 월 네비게이션
          _buildMonthNavigation(context, selectedDate),
          SizedBox(height: AppTheme.spacingMd),

          // 요일 헤더
          _buildWeekdayHeader(context, settings.startDay),
          SizedBox(height: AppTheme.spacingSm),

          // 달력 그리드
          _buildCalendarGrid(context, selectedDate, recordProvider, categoryProvider, settings),
        ],
      ),
    );
  }

  String _formatHeaderDate(DateTime date, String languageCode) {
    if (languageCode == 'ko') {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Widget _buildMonthNavigation(BuildContext context, DateTime date) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            HapticFeedback.lightImpact();
            final prevMonth = DateTime(date.year, date.month - 1, 1);
            context.read<RecordProvider>().selectDate(prevMonth);
          },
        ),
        Text(
          _formatHeaderDate(date, languageCode),
          style: TextStyle(
            fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            HapticFeedback.lightImpact();
            final nextMonth = DateTime(date.year, date.month + 1, 1);
            context.read<RecordProvider>().selectDate(nextMonth);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context, CalendarStartDay startDay) {
    final weekdays = startDay == CalendarStartDay.sunday
        ? const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  Widget _buildCalendarGrid(
    BuildContext context,
    DateTime selectedDate,
    RecordProvider recordProvider,
    CategoryProvider categoryProvider,
    SettingsProvider settings,
  ) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final int startWeekday;
    if (settings.startDay == CalendarStartDay.sunday) {
      startWeekday = firstDayOfMonth.weekday % 7; // Sun=0
    } else {
      startWeekday = (firstDayOfMonth.weekday - 1) % 7; // Mon=0
    }

    final today = DateTime.now();

    // categoryId -> emoji 매핑
    final categoryMap = {
      for (var cat in categoryProvider.categories) cat.id: cat.emoji
    };

    final cells = <Widget>[];

    // 빈 셀 추가 (이전 달)
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // 날짜 셀 추가
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

      // 카테고리 데이터 선택 (최다 활동 or 고정 카테고리)
      ({int categoryId, int minutes})? categoryData;
      if (settings.displayMode == CalendarDisplayMode.topCategory) {
        categoryData = recordProvider.getTopCategoryForDate(date);
      } else {
        final fixedId = settings.fixedCategoryId;
        if (fixedId != null) {
          categoryData = recordProvider.getCategoryForDate(date, fixedId);
        }
      }

      String? emoji;
      int? minutes;
      if (categoryData != null) {
        emoji = categoryMap[categoryData.categoryId];
        minutes = categoryData.minutes;
      }

      final completedChecks = recordProvider.getCompletedCheckCountForDate(date);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        CalendarDayCell(
          day: day,
          isSelected: isSelected,
          isWeekend: isWeekend,
          isToday: isToday,
          emoji: emoji,
          minutes: minutes,
          showTime: settings.showActivityTime,
          completedChecks: settings.showCheckCount ? completedChecks : 0,
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
      childAspectRatio: 0.62,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}
