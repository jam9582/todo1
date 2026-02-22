import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_theme.dart';
import '../../../providers/record_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../l10n/app_localizations.dart';

class TimerBottomSheet extends StatelessWidget {
  final int completedMinutes;

  const TimerBottomSheet({super.key, required this.completedMinutes});

  static void showForCategorySelection(BuildContext context, int minutes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimerBottomSheet(completedMinutes: minutes),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onCategorySelected(BuildContext context, int categoryId) async {
    final recordProvider = context.read<RecordProvider>();
    await recordProvider.updateTimeRecordForToday(categoryId, completedMinutes);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      recordProvider.selectDate(DateTime.now());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.timerAdded),
          backgroundColor: AppColors.snackbar,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.read<CategoryProvider>().categories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.timerSelectCategory,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatElapsed(Duration(minutes: completedMinutes)),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...categories.map((category) => InkWell(
              onTap: () => _onCategorySelected(context, category.id),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
