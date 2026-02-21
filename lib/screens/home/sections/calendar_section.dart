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

class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection>
    with SingleTickerProviderStateMixin {
  // setState 없이 값만 변경 → ValueListenableBuilder만 업데이트
  final _offsetNotifier = ValueNotifier<double>(0.0);
  double _calendarWidth = 0.0;

  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // 스냅 애니메이션도 setState 없이 notifier로만 업데이트
    _snapController.addListener(() {
      if (_snapAnimation != null) {
        _offsetNotifier.value = _snapAnimation!.value;
      }
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    _offsetNotifier.dispose();
    super.dispose();
  }

  // setState 없음 - notifier 직접 업데이트 → 그리드 빌드 없이 Transform만 변경
  void _onDragUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) return;
    _offsetNotifier.value += details.delta.dx;
  }

  Future<void> _snapTo(double target) async {
    _snapAnimation = Tween<double>(
      begin: _offsetNotifier.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOut,
    ));
    await _snapController.forward(from: 0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_snapController.isAnimating) return;
    final width = _calendarWidth;
    final offset = _offsetNotifier.value;
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -500 || offset < -width / 3) {
      await _navigateMonth(isNext: true);
    } else if (velocity > 500 || offset > width / 3) {
      await _navigateMonth(isNext: false);
    } else {
      await _snapTo(0);
      _offsetNotifier.value = 0;
    }
  }

  Future<void> _navigateMonth({required bool isNext}) async {
    final width = _calendarWidth;
    await _snapTo(isNext ? -width : width);
    if (!mounted) return;
    _offsetNotifier.value = 0;
    final date = context.read<RecordProvider>().selectedDate;
    context.read<RecordProvider>().selectDate(
      isNext
          ? DateTime(date.year, date.month + 1, 1)
          : DateTime(date.year, date.month - 1, 1),
    );
    HapticFeedback.lightImpact();
  }

  Future<void> _onButtonTap(bool isNext) async {
    if (_snapController.isAnimating) return;
    await _navigateMonth(isNext: isNext);
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
          onPressed: () => _onButtonTap(false),
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
          onPressed: () => _onButtonTap(true),
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
            context.read<RecordProvider>().selectDate(
              DateTime(month.year, month.month, day),
            );
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

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final selectedDate = recordProvider.selectedDate;

    final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1, 1);
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1, 1);

    // 그리드는 provider 데이터 변경 시에만 빌드 (드래그 중에는 빌드 안 함)
    final prevGrid = _buildCalendarGrid(
        context, prevMonth, selectedDate, recordProvider, categoryProvider, settings);
    final currentGrid = _buildCalendarGrid(
        context, selectedDate, selectedDate, recordProvider, categoryProvider, settings);
    final nextGrid = _buildCalendarGrid(
        context, nextMonth, selectedDate, recordProvider, categoryProvider, settings);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Container(
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
                _calendarWidth = constraints.maxWidth;
                final w = constraints.maxWidth;

                return ClipRect(
                  // ValueListenableBuilder: offset 변경 시 Transform만 업데이트
                  // 그리드(prevGrid/currentGrid/nextGrid)는 빌드되지 않음
                  child: ValueListenableBuilder<double>(
                    valueListenable: _offsetNotifier,
                    builder: (context, offset, _) {
                      return Stack(
                        children: [
                          Transform.translate(
                            offset: Offset(offset - w, 0),
                            child: SizedBox(width: w, child: prevGrid),
                          ),
                          Transform.translate(
                            offset: Offset(offset, 0),
                            child: SizedBox(width: w, child: currentGrid),
                          ),
                          Transform.translate(
                            offset: Offset(offset + w, 0),
                            child: SizedBox(width: w, child: nextGrid),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
