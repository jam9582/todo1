import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _keyStartTime = 'timer_start_time';
  static const _keyAccumulatedMs = 'timer_accumulated_ms';
  static const _keyIsRunning = 'timer_is_running';
  static const _keyIsPaused = 'timer_is_paused';
  // 최초 시작 시각 — 일시정지/재개 사이클에도 유지 (알림 표시용)
  static const _keyOriginalStartTime = 'timer_original_start_time';

  DateTime? _startTime;
  DateTime? _originalStartTime; // 알림에 표시할 최초 시작 시각
  Duration _accumulated = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _ticker;
  SharedPreferences? _prefs;

  // 알림 완료 액션 → HomeScreen이 감지하여 카테고리 바텀시트 표시
  bool _pendingComplete = false;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning || _isPaused;
  bool get pendingComplete => _pendingComplete;

  Duration get elapsed {
    if (_startTime == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_startTime!);
  }

  TimerProvider() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _restore();
    _registerNotificationHandler();
    _processPendingNotificationAction();
  }

  /// 앱 재시작 시 저장된 타이머 상태 복원
  void _restore() {
    final isRunning = _prefs?.getBool(_keyIsRunning) ?? false;
    final isPaused = _prefs?.getBool(_keyIsPaused) ?? false;
    if (!isRunning && !isPaused) return;

    final accumulatedMs = _prefs?.getInt(_keyAccumulatedMs) ?? 0;
    final accumulated = Duration(milliseconds: accumulatedMs);

    // 총 경과 시간이 24시간을 넘으면 자동 리셋
    Duration totalElapsed = accumulated;
    if (isRunning) {
      final startTimeStr = _prefs?.getString(_keyStartTime);
      if (startTimeStr != null) {
        totalElapsed += DateTime.now().difference(DateTime.parse(startTimeStr));
      }
    }
    if (totalElapsed.inHours >= 24) {
      _clearState();
      return;
    }

    _accumulated = accumulated;
    _isRunning = isRunning;
    _isPaused = isPaused;

    final originalStr = _prefs?.getString(_keyOriginalStartTime);
    if (originalStr != null) {
      _originalStartTime = DateTime.tryParse(originalStr);
    }

    if (isRunning) {
      final startTimeStr = _prefs?.getString(_keyStartTime);
      if (startTimeStr != null) {
        _startTime = DateTime.parse(startTimeStr);
        _startTicker();
      }
    }

    // 복원 후 알림 표시 (앱 재시작 시에도 알림 유지)
    _restoreNotification();

    notifyListeners();
  }

  /// 앱 재시작 후 타이머가 활성 상태이면 알림 복원
  void _restoreNotification() {
    if (_originalStartTime == null) return;
    if (_isRunning) {
      NotificationService.showTimerRunning(
        originalStartTime: _originalStartTime!,
        accumulated: _accumulated,
      );
    } else if (_isPaused) {
      NotificationService.showTimerPaused(
        originalStartTime: _originalStartTime!,
      );
    }
  }

  /// 알림 액션 버튼 핸들러 등록 (앱이 살아있을 때)
  void _registerNotificationHandler() {
    NotificationService.setTimerActionHandler((actionId) {
      switch (actionId) {
        case NotificationService.actionPause:
          if (_isRunning) pause();
        case NotificationService.actionResume:
          if (_isPaused) resume();
        case NotificationService.actionComplete:
          if (isActive) {
            _pendingComplete = true;
            notifyListeners();
          }
        case NotificationService.actionCancel:
          if (isActive) cancel();
      }
    });
  }

  /// 앱이 완전 종료된 상태에서 알림 액션이 눌렸을 때 저장된 명령 처리
  void _processPendingNotificationAction() {
    final action = _prefs?.getString(NotificationService.keyPendingAction);
    if (action == null) return;
    _prefs?.remove(NotificationService.keyPendingAction);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (action) {
        case NotificationService.actionPause:
          if (_isRunning) pause();
        case NotificationService.actionResume:
          if (_isPaused) resume();
        case NotificationService.actionComplete:
          if (isActive) {
            _pendingComplete = true;
            notifyListeners();
          }
        case NotificationService.actionCancel:
          if (isActive) cancel();
      }
    });
  }

  void clearPendingComplete() {
    _pendingComplete = false;
  }

  /// 현재 타이머 상태를 디스크에 저장
  void _saveState() {
    if (_prefs == null) return;
    if (_isRunning && _startTime != null) {
      _prefs!.setString(_keyStartTime, _startTime!.toIso8601String());
    } else {
      _prefs!.remove(_keyStartTime);
    }
    if (_originalStartTime != null) {
      _prefs!.setString(
          _keyOriginalStartTime, _originalStartTime!.toIso8601String());
    }
    _prefs!.setInt(_keyAccumulatedMs, _accumulated.inMilliseconds);
    _prefs!.setBool(_keyIsRunning, _isRunning);
    _prefs!.setBool(_keyIsPaused, _isPaused);
  }

  /// 저장된 타이머 상태 삭제
  void _clearState() {
    _prefs?.remove(_keyStartTime);
    _prefs?.remove(_keyOriginalStartTime);
    _prefs?.remove(_keyAccumulatedMs);
    _prefs?.remove(_keyIsRunning);
    _prefs?.remove(_keyIsPaused);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _stopTicker();
      _saveState();
    } else if (state == AppLifecycleState.resumed) {
      _syncFromWidgetIfNeeded();
    }
  }

  /// 위젯이 타이머 상태를 변경했을 때 Flutter 상태 동기화
  void _syncFromWidgetIfNeeded() {
    final hasInteraction = _prefs?.getBool('widget_interaction') ?? false;
    if (!hasInteraction) {
      if (_isRunning) _startTicker();
      return;
    }
    _prefs?.remove('widget_interaction');
    // SharedPreferences에서 최신 타이머 상태 재로드
    _stopTicker();
    _isRunning = false;
    _isPaused = false;
    _startTime = null;
    _accumulated = Duration.zero;
    _restore();
  }

  void start() {
    _startTime = DateTime.now();
    _originalStartTime = _startTime;
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    NotificationService.showTimerRunning(
      originalStartTime: _originalStartTime!,
    );
    WidgetService.syncTimerStartedNoCategory(
      originalStartTime: _originalStartTime!,
    );
    notifyListeners();
  }

  void pause() {
    _accumulated = elapsed;
    _startTime = null;
    _isRunning = false;
    _isPaused = true;
    _stopTicker();
    _saveState();
    if (_originalStartTime != null) {
      NotificationService.showTimerPaused(
        originalStartTime: _originalStartTime!,
      );
    }
    WidgetService.syncTimerPaused();
    notifyListeners();
  }

  void resume() {
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    if (_originalStartTime != null) {
      NotificationService.showTimerRunning(
        originalStartTime: _originalStartTime!,
        accumulated: _accumulated,
      );
    }
    WidgetService.syncTimerResumed();
    notifyListeners();
  }

  void cancel() {
    _reset();
    _clearState();
    NotificationService.cancelTimerNotification();
    WidgetService.syncTimerCleared();
    notifyListeners();
  }

  /// 경과 시간(분 단위)을 반환하고 타이머를 리셋.
  int complete() {
    final minutes = elapsed.inMinutes;
    _reset();
    _clearState();
    NotificationService.cancelTimerNotification();
    WidgetService.syncTimerCleared();
    notifyListeners();
    return minutes;
  }

  void _reset() {
    _startTime = null;
    _originalStartTime = null;
    _accumulated = Duration.zero;
    _isRunning = false;
    _isPaused = false;
    _pendingComplete = false;
    _stopTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
