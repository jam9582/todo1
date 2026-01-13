import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/record_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';

class DailyMessageSection extends StatelessWidget {
  const DailyMessageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final message = recordProvider.currentRecord?.message ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.wp(context, 6), // 화면 너비의 6%
        vertical: AppTheme.spacingMd,
      ),
      color: AppTheme.backgroundColor,
      child: Text(
        message.isEmpty ? '오늘은 집중이 잘 되어서\n업무를 많이 해치울 수 있었다!' : message,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, AppTheme.fontSizeBody),
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}
