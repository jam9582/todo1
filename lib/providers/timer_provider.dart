import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _keyStartTime = 'timer_start_time';
  static const _keyAccumulatedMs = 'timer_accumulated_ms';
  static const _keyIsRunning = 'timer_is_running';
  static const _keyIsPaused = 'timer_is_paused';

  DateTime? _startTime;
  Duration _accumulated = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _ticker;
  SharedPreferences? _prefs;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning || _isPaused;

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

    if (isRunning) {
      final startTimeStr = _prefs?.getString(_keyStartTime);
      if (startTimeStr != null) {
        _startTime = DateTime.parse(startTimeStr);
        _startTicker();
      }
    }

    notifyListeners();
  }

  /// 현재 타이머 상태를 디스크에 저장
  void _saveState() {
    if (_prefs == null) return;
    if (_isRunning && _startTime != null) {
      _prefs!.setString(_keyStartTime, _startTime!.toIso8601String());
    } else {
      _prefs!.remove(_keyStartTime);
    }
    _prefs!.setInt(_keyAccumulatedMs, _accumulated.inMilliseconds);
    _prefs!.setBool(_keyIsRunning, _isRunning);
    _prefs!.setBool(_keyIsPaused, _isPaused);
  }

  /// 저장된 타이머 상태 삭제
  void _clearState() {
    _prefs?.remove(_keyStartTime);
    _prefs?.remove(_keyAccumulatedMs);
    _prefs?.remove(_keyIsRunning);
    _prefs?.remove(_keyIsPaused);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _stopTicker();
      _saveState(); // 백그라운드 전환 시 상태 저장
    } else if (state == AppLifecycleState.resumed && _isRunning) {
      _startTicker();
    }
  }

  void start() {
    _startTime = DateTime.now();
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    notifyListeners();
  }

  void pause() {
    _accumulated = elapsed;
    _startTime = null;
    _isRunning = false;
    _isPaused = true;
    _stopTicker();
    _saveState();
    notifyListeners();
  }

  void resume() {
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    _saveState();
    notifyListeners();
  }

  void cancel() {
    _reset();
    _clearState();
    notifyListeners();
  }

  /// 경과 시간(분 단위)을 반환하고 타이머를 리셋.
  int complete() {
    final minutes = elapsed.inMinutes;
    _reset();
    _clearState();
    notifyListeners();
    return minutes;
  }

  void _reset() {
    _startTime = null;
    _accumulated = Duration.zero;
    _isRunning = false;
    _isPaused = false;
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
