import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/record_provider.dart';
import '../../../models/extensions.dart';
import '../widgets/category_button.dart';
import '../widgets/time_input_dialog.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final recordProvider = context.watch<RecordProvider>();

    if (categoryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        color: AppColors.background,
        child: Center(
          child: Text(
            '카테고리를 만들어보세요!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((category) {
          final minutes = recordProvider.getMinutesForCategory(category.id);
          final timeString = minutes.toTimeString();

          return Expanded(
            child: CategoryButton(
              emoji: category.emoji,
              name: category.name,
              time: timeString,
              isSelected: minutes > 0,
              onTap: () async {
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
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
