import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// iOS Live Activity (Dynamic Island + Lock Screen) 관리 서비스.
/// MethodChannel로 네이티브 ActivityKit API를 호출.
class LiveActivityService {
  static const _channel = MethodChannel('com.example.todo1/liveActivity');

  /// Live Activity 시작 (타이머 시작 시 호출)
  static Future<void> startActivity({
    required int categoryId,
    required String categoryName,
    required String categoryEmoji,
    required DateTime startTime,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('startActivity', {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryEmoji': categoryEmoji,
        'startTime': startTime.millisecondsSinceEpoch,
      });
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    }
  }

  /// Live Activity 업데이트 — 일시정지
  static Future<void> updatePaused({required Duration accumulated}) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('updateActivity', {
        'isPaused': true,
        'accumulatedMs': accumulated.inMilliseconds,
      });
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    }
  }

  /// Live Activity 업데이트 — 재개
  static Future<void> updateResumed({required Duration accumulated}) async {
    if (!Platform.isIOS) return;
    try {
      final displayDate = DateTime.now().subtract(accumulated);
      await _channel.invokeMethod('updateActivity', {
        'isPaused': false,
        'accumulatedMs': accumulated.inMilliseconds,
        'timerStartDate': displayDate.millisecondsSinceEpoch,
      });
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    }
  }

  /// Live Activity 종료 (완료/취소 시 호출)
  static Future<void> endActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('endActivity');
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    }
  }
}
