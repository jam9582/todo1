import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/purchase_provider.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdRemoved = context.watch<PurchaseProvider>().isAdRemoved;
    if (isAdRemoved) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 60,
      color: AppColors.adBanner,
      alignment: Alignment.center,
      child: const Text(
        '광고영역',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
