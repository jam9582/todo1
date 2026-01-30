import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
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

    // 체크박스가 없으면 표시하지 않음
    if (checkBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: checkBoxes.map((checkBox) {
          final isCompleted = recordProvider.isCheckBoxCompleted(checkBox.id);

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                recordProvider.toggleCheckBox(checkBox.id);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 24,
                    color: isCompleted ? AppColors.textPrimary : AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: Text(
                      checkBox.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted
                            ? AppColors.textPrimary
                            : AppColors.grey400,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
