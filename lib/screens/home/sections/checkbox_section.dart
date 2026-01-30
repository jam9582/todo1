import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../models/check_box.dart';
import '../../../providers/check_box_provider.dart';
import '../../../providers/record_provider.dart';

class CheckboxSection extends StatefulWidget {
  const CheckboxSection({super.key});

  @override
  State<CheckboxSection> createState() => _CheckboxSectionState();
}

class _CheckboxSectionState extends State<CheckboxSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    // 페이지별로 2개씩 그룹화
    final List<List<CheckBox>> pages = [];
    for (int i = 0; i < checkBoxes.length; i += 2) {
      pages.add(
        checkBoxes.sublist(i, i + 2 > checkBoxes.length ? checkBoxes.length : i + 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 체크박스 PageView
          SizedBox(
            height: 80, // 2개 세로 배치 높이
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                final pageItems = pages[pageIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pageItems.map((checkBox) {
                      final isCompleted = recordProvider.isCheckBoxCompleted(checkBox.id);
                      return _buildCheckBoxItem(checkBox, isCompleted, recordProvider);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          // 페이지 인디케이터 (페이지가 2개 이상일 때만 표시)
          if (pages.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.textPrimary
                        : AppColors.grey300,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckBoxItem(CheckBox checkBox, bool isCompleted, RecordProvider recordProvider) {
    return GestureDetector(
      onTap: () {
        recordProvider.toggleCheckBox(checkBox.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 24,
              color: isCompleted ? AppColors.textPrimary : AppColors.grey400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                checkBox.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? AppColors.textPrimary : AppColors.grey400,
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
  }
}
