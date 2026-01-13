import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/record_provider.dart';

class DailyMessageSection extends StatelessWidget {
  const DailyMessageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final message = recordProvider.currentRecord?.message ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Text(
        message.isEmpty ? '오늘은 집중이 잘 되어서\n업무를 많이 해치울 수 있었다!' : message,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}
