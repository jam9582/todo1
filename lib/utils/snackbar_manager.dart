import 'package:flutter/material.dart';
import '../constants/durations.dart';

/// SnackBar 중복 표시 방지를 위한 매니저
class SnackBarManager {
  static bool _isShowing = false;

  /// SnackBar가 현재 표시 중인지 확인
  static bool get isShowing => _isShowing;

  /// SnackBar 표시 (이미 표시 중이면 무시)
  static void show(BuildContext context, SnackBar snackBar) {
    if (_isShowing) return;

    _isShowing = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar)
        .closed
        .then((_) => _isShowing = false);
  }

  /// 간단한 텍스트 SnackBar 표시
  static void showText(BuildContext context, String message) {
    show(
      context,
      SnackBar(
        content: Text(message),
        duration: AppDurations.snackBar,
      ),
    );
  }

  /// 현재 SnackBar 닫기
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _isShowing = false;
  }
}
