import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/durations.dart';

/// SnackBar 중복 표시 방지를 위한 매니저
/// - 같은 메시지: 표시 중이면 차단
/// - 다른 메시지: 현재 스낵바 닫고 새로 표시
class SnackBarManager {
  static String? _currentMessage;

  /// SnackBar가 현재 표시 중인지 확인
  static bool get isShowing => _currentMessage != null;

  /// 현재 표시 중인 메시지
  static String? get currentMessage => _currentMessage;

  /// 간단한 텍스트 SnackBar 표시
  static void showText(BuildContext context, String message) {
    // 같은 메시지면 차단
    if (_currentMessage == message) return;

    // 다른 메시지가 표시 중이면 닫기
    if (_currentMessage != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    _currentMessage = message;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textOnSnackbar),
            ),
            backgroundColor: AppColors.snackbar,
            duration: AppDurations.snackBar,
          ),
        )
        .closed
        .then((_) {
          // 현재 메시지와 같을 때만 초기화 (다른 메시지로 교체된 경우 제외)
          if (_currentMessage == message) {
            _currentMessage = null;
          }
        });
  }

  /// 현재 SnackBar 닫기
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _currentMessage = null;
  }
}
