import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_theme.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/record_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../l10n/app_localizations.dart';

class TimerBottomSheet extends StatefulWidget {
  const TimerBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TimerProvider>(),
        child: const TimerBottomSheet(),
      ),
    );
  }

  @override
  State<TimerBottomSheet> createState() => _TimerBottomSheetState();
}

class _TimerBottomSheetState extends State<TimerBottomSheet> {
  bool _isSelectingCategory = false;
  int _completedMinutes = 0;

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _onComplete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = context.read<TimerProvider>().complete();
    if (minutes <= 0) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.timerTooShort),
          backgroundColor: AppColors.snackbar,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _completedMinutes = minutes;
      _isSelectingCategory = true;
    });
  }

  Future<void> _onCategorySelected(BuildContext context, int categoryId) async {
    final recordProvider = context.read<RecordProvider>();
    await recordProvider.updateTimeRecordForToday(categoryId, _completedMinutes);
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _isSelectingCategory
          ? _buildCategorySelector(context, l10n)
          : _buildTimer(context, l10n),
    );
  }

  Widget _buildTimer(BuildContext context, AppLocalizations l10n) {
    final timerProvider = context.watch<TimerProvider>();
    final elapsed = timerProvider.elapsed;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // 타이틀
          Text(
            l10n.timerTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // 타이머 숫자
          Text(
            _formatElapsed(elapsed),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w200,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 48),
          // 버튼
          if (!timerProvider.isActive)
            _buildPrimaryButton(
              label: l10n.timerStart,
              onTap: () => context.read<TimerProvider>().start(),
            )
          else if (timerProvider.isRunning)
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    label: l10n.timerPause,
                    onTap: () => context.read<TimerProvider>().pause(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryButton(
                    label: l10n.timerComplete,
                    onTap: () => _onComplete(context),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    label: l10n.cancel,
                    onTap: () {
                      context.read<TimerProvider>().cancel();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryButton(
                    label: l10n.timerResume,
                    onTap: () => context.read<TimerProvider>().resume(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryButton(
                    label: l10n.timerComplete,
                    onTap: () => _onComplete(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, AppLocalizations l10n) {
    final categories = context.read<CategoryProvider>().categories;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
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
            _formatElapsed(Duration(minutes: _completedMinutes)),
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
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
