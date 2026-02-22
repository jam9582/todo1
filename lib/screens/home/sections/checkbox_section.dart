import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../models/check_box.dart';
import '../../../providers/check_box_provider.dart';
import '../../../providers/record_provider.dart';

class CheckboxSection extends StatelessWidget {
  const CheckboxSection({super.key});

  @override
  Widget build(BuildContext context) {
    final checkBoxProvider = context.watch<CheckBoxProvider>();
    final recordProvider = context.watch<RecordProvider>();

    if (checkBoxProvider.isLoading) {
      return const SizedBox.shrink();
    }

    final checkBoxes = checkBoxProvider.checkBoxes;

    if (checkBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    final isFutureDate = recordProvider.isFutureDate;

    // 2열 그리드: Row 당 2개씩 배치
    final List<List<CheckBox>> rows = [];
    for (int i = 0; i < checkBoxes.length; i += 2) {
      rows.add(
        checkBoxes.sublist(i, i + 2 > checkBoxes.length ? checkBoxes.length : i + 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((rowItems) {
          return Row(
            children: [
              Expanded(
                child: _buildCheckBoxItem(rowItems[0], recordProvider.isCheckBoxCompleted(rowItems[0].id), recordProvider, isFutureDate),
              ),
              if (rowItems.length > 1)
                Expanded(
                  child: _buildCheckBoxItem(rowItems[1], recordProvider.isCheckBoxCompleted(rowItems[1].id), recordProvider, isFutureDate),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckBoxItem(CheckBox checkBox, bool isCompleted, RecordProvider recordProvider, bool isFutureDate) {
    return GestureDetector(
      onTap: isFutureDate ? null : () {
        HapticFeedback.lightImpact();
        recordProvider.toggleCheckBox(checkBox.id);
      },
      child: Opacity(
        opacity: isFutureDate ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 24,
                color: isCompleted ? AppColors.grey400 : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  checkBox.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? AppColors.grey400 : AppColors.textPrimary,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
