import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/record_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../l10n/app_localizations.dart';

class DailyMessageSection extends StatefulWidget {
  const DailyMessageSection({super.key});

  @override
  State<DailyMessageSection> createState() => _DailyMessageSectionState();
}

class _DailyMessageSectionState extends State<DailyMessageSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(String currentMessage) {
    _controller.text = currentMessage;
    setState(() => _isEditing = true);
    Future.microtask(() => _focusNode.requestFocus());
  }

  void _saveMessage(BuildContext context) {
    final text = _controller.text.trim();
    context.read<RecordProvider>().updateMessage(text);
    setState(() => _isEditing = false);
    _focusNode.unfocus();
  }

  void _toggleRestDay(BuildContext context) {
    if (_isEditing) _saveMessage(context);
    final recordProvider = context.read<RecordProvider>();
    final isRestDay = recordProvider.isCurrentRestDay;
    if (isRestDay) {
      recordProvider.deactivateRestDay();
    } else {
      final l10n = AppLocalizations.of(context)!;
      recordProvider.activateRestDay(l10n.restDayFill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final message = recordProvider.currentRecord?.message ?? '';
    final isRestDay = recordProvider.isCurrentRestDay;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: 20,
        bottom: AppTheme.spacingMd,
      ),
      color: AppColors.background,
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.textOnAccent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dailyMessageLabel,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeCaption),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _isEditing
                      ? _buildTextField(context, l10n)
                      : _buildDisplayText(context, message, l10n),
                ),
                const SizedBox(width: 8),
                _buildRestDayButton(context, isRestDay, l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayButton(BuildContext context, bool isRestDay, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _toggleRestDay(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isRestDay ? AppColors.grey500 : Colors.transparent,
          border: Border.all(
            color: isRestDay ? AppColors.grey500 : AppColors.grey400,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.restDay,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 11),
            color: isRestDay ? AppColors.textOnAccent : AppColors.grey500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayText(BuildContext context, String message, AppLocalizations l10n) {
    final hasMessage = message.isNotEmpty;
    return GestureDetector(
      onTap: () => _startEditing(message),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 6),
            child: Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.grey400,
            ),
          ),
          Expanded(
            child: Text(
              hasMessage ? message : l10n.dailyMessagePlaceholder,
              textAlign: TextAlign.left,
              softWrap: true,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
                color: hasMessage ? AppColors.textPrimary : AppColors.grey500,
                height: 1.5,
                fontStyle: hasMessage ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.left,
      maxLines: null,
      textInputAction: TextInputAction.done,
      style: TextStyle(
        fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: l10n.dailyMessagePlaceholder,
        hintStyle: const TextStyle(
          color: AppColors.grey500,
          fontStyle: FontStyle.italic,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (_) => _saveMessage(context),
      onTapOutside: (_) => _saveMessage(context),
    );
  }
}
