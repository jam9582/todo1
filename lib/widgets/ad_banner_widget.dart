import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
