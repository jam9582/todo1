import 'package:flutter/material.dart';

class Responsive {
  // 기준 화면 너비 (iPhone SE)
  static const double baseWidth = 375.0;

  // 화면 너비 가져오기
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // 화면 높이 가져오기
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // 반응형 폰트 크기
  static double fontSize(BuildContext context, double size) {
    final width = screenWidth(context);
    if (width < 360) return size * 0.9; // 작은 폰
    if (width > 600) return size * 1.1; // 큰 폰/태블릿
    return size;
  }

  // 반응형 spacing
  static double spacing(BuildContext context, double size) {
    final width = screenWidth(context);
    final scale = width / baseWidth;
    return size * scale;
  }

  // 화면 너비 비율로 계산
  static double wp(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  // 화면 높이 비율로 계산
  static double hp(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }

  // 작은 폰인지 체크
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  // 큰 폰/태블릿인지 체크
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) > 600;
  }
}
