import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/record_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/calendar_day_cell.dart';

class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  static const int _initialPage = 5000;
  late final PageController _pageController;
  late final DateTime _baseMonth;
  int _lastSettledPage = _initialPage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _initialPage);
    // onPageChanged(절반 넘으면 발동) 대신, 완전히 정착했을 때만 업데이트
    _pageController.addListener(_onPageControllerChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageControllerChanged);
    _pageController.dispose();
    super.dispose();
  }

  DateTime _indexToMonth(int index) {
    final offset = index - _initialPage;
    final totalMonths = _baseMonth.year * 12 + (_baseMonth.month - 1) + offset;
    return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1);
  }

  void _onPageControllerChanged() {
    final page = _pageController.page;
    if (page == null) return;
    final rounded = page.round();
    // 페이지가 완전히 정착(소수점 없는 정수값)됐을 때만 업데이트
    if ((page - rounded).abs() < 0.01 && rounded != _lastSettledPage) {
      _lastSettledPage = rounded;
      final newMonth = _indexToMonth(rounded);
      context.read<RecordProvider>().selectDate(
        DateTime(newMonth.year, newMonth.month, 1),
      );
    }
  }

  void _onButtonTap(bool isNext) {
    final currentPage = _pageController.page?.round() ?? _initialPage;
    _pageController.animateToPage(
      isNext ? currentPage + 1 : currentPage - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _formatHeaderDate(DateTime date, AppLocalizations l10n) {
    return l10n.calendarHeaderDate(
      '${date.year}',
      '${date.month}',
      '${date.day}',
    );
  }

  Widget _buildMonthNavigation(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _onButtonTap(false),
        ),
        Text(
          _formatHeaderDate(date, l10n),
          style: TextStyle(
            fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.textPrimary : AppColors.grey500,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _onButtonTap(true),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context, CalendarStartDay startDay) {
    final l10n = AppLocalizations.of(context)!;
    final allDays = [
      l10n.weekdaySun, l10n.weekdayMon, l10n.weekdayTue,
      l10n.weekdayWed, l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat,
    ];
    final weekdays = startDay == CalendarStartDay.sunday
        ? allDays
        : [...allDays.sublist(1), allDays[0]];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.asMap().entries.map((entry) {
        final day = entry.value;
        final isWeekend = startDay == CalendarStartDay.sunday
            ? (entry.key == 0 || entry.key == 6)
            : (entry.key == 5 || entry.key == 6);
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

  List<Widget> _buildCells(
    BuildContext context,
    DateTime month,
    DateTime selectedDate,
    RecordProvider recordProvider,
    CategoryProvider categoryProvider,
    SettingsProvider settings,
  ) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final int startWeekday;
    if (settings.startDay == CalendarStartDay.sunday) {
      startWeekday = firstDayOfMonth.weekday % 7;
    } else {
      startWeekday = (firstDayOfMonth.weekday - 1) % 7;
    }

    final today = DateTime.now();
    final categoryMap = {
      for (var cat in categoryProvider.categories) cat.id: cat.emoji
    };

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

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
      final isRestDay = recordProvider.getIsRestDayForDate(date);

      cells.add(
        CalendarDayCell(
          day: day,
          isSelected: isSelected,
          isWeekend: isWeekend,
          isToday: isToday,
          isRestDay: isRestDay,
          emoji: isRestDay ? null : emoji,
          minutes: isRestDay ? null : minutes,
          showTime: settings.showActivityTime,
          completedChecks: settings.showCheckCount ? completedChecks : 0,
          onTap: () {
            context.read<RecordProvider>().selectDate(
              DateTime(month.year, month.month, day),
            );
          },
        ),
      );
    }

    return cells;
  }

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
          _buildMonthNavigation(context, selectedDate),
          SizedBox(height: AppTheme.spacingMd),
          _buildWeekdayHeader(context, settings.startDay),
          SizedBox(height: AppTheme.spacingSm),
          LayoutBuilder(
            builder: (context, constraints) {
              // 6행 기준 고정 높이 계산 (childAspectRatio: 0.62, crossAxisSpacing: 4, mainAxisSpacing: 4)
              final cellWidth = (constraints.maxWidth - 6 * 4) / 7;
              final cellHeight = cellWidth / 0.62;
              final gridHeight = 6 * cellHeight + 5 * 4;

              return SizedBox(
                height: gridHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    final month = _indexToMonth(index);
                    return GridView.count(
                      crossAxisCount: 7,
                      childAspectRatio: 0.62,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _buildCells(
                        context, month, selectedDate,
                        recordProvider, categoryProvider, settings,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
