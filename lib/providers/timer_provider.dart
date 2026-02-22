import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  DateTime? _startTime;
  Duration _accumulated = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _ticker;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning || _isPaused;

  Duration get elapsed {
    if (_startTime == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_startTime!);
  }

  TimerProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      _startTicker();
    } else if (state == AppLifecycleState.paused && _isRunning) {
      _stopTicker();
    }
  }

  void start() {
    _startTime = DateTime.now();
    _accumulated = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    _accumulated = elapsed;
    _startTime = null;
    _isRunning = false;
    _isPaused = true;
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void cancel() {
    _reset();
    notifyListeners();
  }

  /// 경과 시간(분 단위)을 반환하고 타이머를 리셋.
  int complete() {
    final minutes = elapsed.inMinutes;
    _reset();
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
