import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/record_provider.dart';
import '../../../providers/timer_provider.dart';
import '../../../models/extensions.dart';
import '../widgets/category_button.dart';
import '../widgets/time_input_dialog.dart';
import '../../../l10n/app_localizations.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final recordProvider = context.watch<RecordProvider>();
    final timerProvider = context.watch<TimerProvider>();

    if (categoryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isFutureDate = recordProvider.isFutureDate;
    final categories = categoryProvider.categories;
    final isSelecting = timerProvider.isSelecting;
    final isTimerActive = timerProvider.isActive;
    final activeCategoryId = timerProvider.categoryId;

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.background,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.emptyCategoryMessage,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.asMap().entries.map((entry) {
          final i = entry.key;
          final category = entry.value;
          final minutes = recordProvider.getMinutesForCategory(category.id);
          final timeString = minutes.toTimeString();

          // 타이머 측정 중: 활성 카테고리만 선명, 나머지 흐리게
          final isDimmed = isTimerActive &&
              activeCategoryId != null &&
              activeCategoryId != category.id;

          // 카테고리 선택 대기 중: 모든 버튼 펄스 테두리
          final isHighlighted = isSelecting;

          VoidCallback onTap;
          if (isSelecting) {
            // 카테고리 선택 → 해당 카테고리로 타이머 시작
            onTap = () => timerProvider.startWithCategory(
                  categoryId: category.id,
                  categoryName: category.name,
                  categoryEmoji: category.emoji,
                  colorIndex: i,
                );
          } else if (isTimerActive) {
            // 타이머 측정 중엔 카테고리 버튼 비활성
            onTap = () {};
          } else {
            // 평상시: 시간 직접 입력 다이얼로그
            onTap = () async {
              final result = await TimeInputDialog.show(
                context,
                category: category,
                initialMinutes: minutes,
              );
              if (result != null && context.mounted) {
                context.read<RecordProvider>().updateTimeRecord(
                      category.id,
                      result,
                    );
              }
            };
          }

          return Expanded(
            child: CategoryButton(
              emoji: category.emoji,
              name: category.name,
              time: timeString,
              isSelected: minutes > 0,
              enabled: !isFutureDate && !isTimerActive,
              isHighlighted: isHighlighted && !isFutureDate,
              isDimmed: isDimmed,
              onTap: onTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}
