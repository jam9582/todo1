import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/live_activity_service.dart';

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _keyStartTime = 'timer_start_time';
  static const _keyAccumulatedMs = 'timer_accumulated_ms';
  static const _keyIsRunning = 'timer_is_running';
  static const _keyIsPaused = 'timer_is_paused';
  static const _keyOriginalStartTime = 'timer_original_start_time';
  static const _keyCategoryId = 'timer_category_id';
  static const _keyCategoryName = 'timer_category_name';
  static const _keyCategoryEmoji = 'timer_category_emoji';

  DateTime? _startTime;
  DateTime? _originalStartTime;
  Duration _accumulated = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isSelecting = false; // 타이머 버튼 탭 후 카테고리 선택 대기 중
  int? _categoryId;
  String? _categoryName;
  String? _categoryEmoji;
  Timer? _ticker;
  SharedPreferences? _prefs;

  bool _pendingComplete = false;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning || _isPaused;
  bool get isSelecting => _isSelecting;
  int? get categoryId => _categoryId;
  String? get categoryName => _categoryName;
  String? get categoryEmoji => _categoryEmoji;
  bool get pendingComplete => _pendingComplete;

  Duration get elapsed {
    final startTime = _startTime;
    if (startTime == null) return _accumulated;
    return _accumulated + DateTime.now().difference(startTime);
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
      final parsedStart = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
      if (parsedStart != null) {
        totalElapsed += DateTime.now().difference(parsedStart);
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

    _categoryId = _prefs?.getInt(_keyCategoryId);
    _categoryName = _prefs?.getString(_keyCategoryName);
    _categoryEmoji = _prefs?.getString(_keyCategoryEmoji);

    if (isRunning) {
      final startTimeStr = _prefs?.getString(_keyStartTime);
      final parsedStart = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
      if (parsedStart != null) {
        _startTime = parsedStart;
        _startTicker();
      }
    }

    // 복원 후 알림 표시 (앱 재시작 시에도 알림 유지)
    _restoreNotification();

    notifyListeners();
  }

  /// 앱 재시작 후 타이머가 활성 상태이면 알림 + Live Activity 복원
  void _restoreNotification() {
    final originalStartTime = _originalStartTime;
    if (originalStartTime == null) return;
    if (_isRunning) {
      NotificationService.showTimerRunning(
        originalStartTime: originalStartTime,
        accumulated: _accumulated,
      );
      // Live Activity도 복원
      LiveActivityService.startActivity(
        categoryId: _categoryId ?? -1,
        categoryName: _categoryName ?? '',
        categoryEmoji: _categoryEmoji ?? '',
        startTime: originalStartTime,
      );
      // running 상태: accumulated가 있으면 displayDate 업데이트
      if (_accumulated > Duration.zero) {
        LiveActivityService.updateResumed(accumulated: _accumulated);
      }
    } else if (_isPaused) {
      NotificationService.showTimerPaused(
        originalStartTime: originalStartTime,
      );
      LiveActivityService.startActivity(
        categoryId: _categoryId ?? -1,
        categoryName: _categoryName ?? '',
        categoryEmoji: _categoryEmoji ?? '',
        startTime: originalStartTime,
      );
      LiveActivityService.updatePaused(accumulated: _accumulated);
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
    final prefs = _prefs;
    if (prefs == null) return;
    final startTime = _startTime;
    if (_isRunning && startTime != null) {
      prefs.setString(_keyStartTime, startTime.toIso8601String());
    } else {
      prefs.remove(_keyStartTime);
    }
    final originalStartTime = _originalStartTime;
    if (originalStartTime != null) {
      prefs.setString(
          _keyOriginalStartTime, originalStartTime.toIso8601String());
    }
    prefs.setInt(_keyAccumulatedMs, _accumulated.inMilliseconds);
    prefs.setBool(_keyIsRunning, _isRunning);
    prefs.setBool(_keyIsPaused, _isPaused);
    final categoryId = _categoryId;
    if (categoryId != null) {
      prefs.setInt(_keyCategoryId, categoryId);
      prefs.setString(_keyCategoryName, _categoryName ?? '');
      prefs.setString(_keyCategoryEmoji, _categoryEmoji ?? '');
    } else {
      prefs.remove(_keyCategoryId);
      prefs.remove(_keyCategoryName);
      prefs.remove(_keyCategoryEmoji);
    }
  }

  /// 저장된 타이머 상태 삭제
  void _clearState() {
    _prefs?.remove(_keyStartTime);
    _prefs?.remove(_keyOriginalStartTime);
    _prefs?.remove(_keyAccumulatedMs);
    _prefs?.remove(_keyIsRunning);
    _prefs?.remove(_keyIsPaused);
    _prefs?.remove(_keyCategoryId);
    _prefs?.remove(_keyCategoryName);
    _prefs?.remove(_keyCategoryEmoji);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _stopTicker();
      _saveState();
    } else if (state == AppLifecycleState.resumed) {
      _syncFromWidgetIfNeeded();
      _processIOSWidgetInteraction(); // iOS 위젯 인터랙션 처리 (비동기)
    }
  }

  /// Android 위젯이 타이머 상태를 변경했을 때 Flutter 상태 동기화
  Future<void> _syncFromWidgetIfNeeded() async {
    await _prefs?.reload(); // 네이티브 위젯(Kotlin)이 쓴 최신 값 반영
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

  /// iOS 위젯 App Intent가 저장한 액션을 읽고 적용
  Future<void> _processIOSWidgetInteraction() async {
    final action = await WidgetService.popIOSWidgetAction();
    if (action == null) return;

    switch (action) {
      case 'pause':
        if (_isRunning) pause();
      case 'resume':
        if (_isPaused) resume();
      case 'complete':
        if (isActive) {
          _pendingComplete = true;
          notifyListeners();
        }
      case 'cancel':
        if (isActive) cancel();
      case 'start':
        final startTimeStr = await WidgetService.popIOSWidgetStartTime();
        if (startTimeStr != null) _startFromWidgetTime(startTimeStr);
    }
  }

  /// iOS 위젯에서 시작된 타이머를 startTime 기준으로 복원
  void _startFromWidgetTime(String startTimeStr) {
    final startTime = DateTime.tryParse(startTimeStr);
    if (startTime == null) return;
    _startTime = startTime;
    _originalStartTime = startTime;
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    NotificationService.showTimerRunning(originalStartTime: startTime);
    notifyListeners();
  }

  /// 앱 타이머 버튼 탭 → 카테고리 선택 대기 상태로 전환
  void startSelecting() {
    _isSelecting = true;
    notifyListeners();
  }

  /// 카테고리 선택 취소 (타이머 버튼 재탭 등)
  void cancelSelecting() {
    _isSelecting = false;
    notifyListeners();
  }

  void start() {
    final now = DateTime.now();
    _startTime = now;
    _originalStartTime = now;
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _isSelecting = false;
    _startTicker();
    _saveState();
    NotificationService.showTimerRunning(originalStartTime: now);
    WidgetService.syncTimerStartedNoCategory(originalStartTime: now);
    LiveActivityService.startActivity(
      categoryId: -1,
      categoryName: '',
      categoryEmoji: '',
      startTime: now,
    );
    notifyListeners();
  }

  /// 카테고리 선택 후 타이머 시작 (앱/iOS 위젯 공용)
  void startWithCategory({
    required int categoryId,
    required String categoryName,
    required String categoryEmoji,
    required int colorIndex,
  }) {
    final now = DateTime.now();
    _startTime = now;
    _originalStartTime = now;
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _isSelecting = false;
    _categoryId = categoryId;
    _categoryName = categoryName;
    _categoryEmoji = categoryEmoji;
    _startTicker();
    _saveState();
    NotificationService.showTimerRunning(originalStartTime: now);
    WidgetService.syncTimerStarted(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryEmoji: categoryEmoji,
      colorIndex: colorIndex,
      originalStartTime: now,
    );
    LiveActivityService.startActivity(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryEmoji: categoryEmoji,
      startTime: now,
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
    final originalStartTime = _originalStartTime;
    if (originalStartTime != null) {
      NotificationService.showTimerPaused(
        originalStartTime: originalStartTime,
      );
    }
    WidgetService.syncTimerPaused(elapsed: _accumulated);
    LiveActivityService.updatePaused(accumulated: _accumulated);
    notifyListeners();
  }

  void resume() {
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    final originalStartTime = _originalStartTime;
    if (originalStartTime != null) {
      NotificationService.showTimerRunning(
        originalStartTime: originalStartTime,
        accumulated: _accumulated,
      );
    }
    WidgetService.syncTimerResumed(accumulated: _accumulated);
    LiveActivityService.updateResumed(accumulated: _accumulated);
    notifyListeners();
  }

  void cancel() {
    _reset();
    _clearState();
    NotificationService.cancelTimerNotification();
    WidgetService.syncTimerCleared();
    LiveActivityService.endActivity();
    notifyListeners();
  }

  /// 경과 시간(분)과 카테고리 정보를 반환하고 타이머를 리셋.
  ({int minutes, int? categoryId, String? categoryName}) complete() {
    final minutes = elapsed.inMinutes;
    final categoryId = _categoryId;
    final categoryName = _categoryName;
    _reset();
    _clearState();
    NotificationService.cancelTimerNotification();
    WidgetService.syncTimerCleared();
    LiveActivityService.endActivity();
    notifyListeners();
    return (minutes: minutes, categoryId: categoryId, categoryName: categoryName);
  }

  void _reset() {
    _startTime = null;
    _originalStartTime = null;
    _accumulated = Duration.zero;
    _isRunning = false;
    _isPaused = false;
    _isSelecting = false;
    _categoryId = null;
    _categoryName = null;
    _categoryEmoji = null;
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
