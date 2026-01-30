import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/record_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive.dart';

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

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final message = recordProvider.currentRecord?.message ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: AppTheme.spacingSm,
      ),
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 한마디',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, AppTheme.fontSizeCaption),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          _isEditing ? _buildTextField(context) : _buildDisplayText(message),
        ],
      ),
    );
  }

  Widget _buildDisplayText(String message) {
    final hasMessage = message.isNotEmpty;
    return GestureDetector(
      onTap: () => _startEditing(message),
      child: Text(
        hasMessage ? message : '언제나 당신을 응원해요',
        textAlign: TextAlign.left,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
          color: hasMessage ? AppColors.textPrimary : AppColors.grey500,
          height: 1.5,
          fontStyle: hasMessage ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
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
      decoration: const InputDecoration(
        hintText: '언제나 당신을 응원해요',
        hintStyle: TextStyle(
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
