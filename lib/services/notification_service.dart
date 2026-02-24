import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// 앱이 완전히 종료된 상태에서 알림 액션 버튼을 눌렀을 때 호출되는 핸들러.
/// 별도 isolate에서 실행되므로 SharedPreferences에 명령을 저장하고 종료.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  if (response.id == NotificationService.timerNotifId &&
      response.actionId != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        NotificationService.keyPendingAction, response.actionId!);
  }
}

class NotificationService {
  // ─── 매일 알림 ──────────────────────────────────────────────────────────
  static const _dailyChannelId = 'todo1_daily';
  static const _dailyChannelName = '매일 알림';
  static const _dailyNotifId = 0;

  // ─── 타이머 알림 ─────────────────────────────────────────────────────────
  static const _timerChannelId = 'todo1_timer';
  static const _timerChannelName = '타임워치';
  static const timerNotifId = 1;

  // 알림 액션 ID (TimerProvider와 공유)
  static const actionPause = 'TIMER_PAUSE';
  static const actionResume = 'TIMER_RESUME';
  static const actionComplete = 'TIMER_COMPLETE';
  static const actionCancel = 'TIMER_CANCEL';

  // 앱 종료 중 액션 저장용 SharedPreferences 키
  static const keyPendingAction = 'timer_pending_action';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 앱이 살아있을 때 타이머 액션 버튼 처리 콜백 (TimerProvider가 등록)
  static void Function(String actionId)? _timerActionHandler;

  static void setTimerActionHandler(void Function(String actionId) handler) {
    _timerActionHandler = handler;
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    if (response.id == timerNotifId && response.actionId != null) {
      _timerActionHandler?.call(response.actionId!);
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: 타이머 측정 중 / 일시정지 두 가지 카테고리 등록
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'TIMER_RUNNING',
          actions: [
            DarwinNotificationAction.plain(actionPause, '일시정지'),
            DarwinNotificationAction.plain(actionComplete, '완료'),
            DarwinNotificationAction.plain(
              actionCancel,
              '취소',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          'TIMER_PAUSED',
          actions: [
            DarwinNotificationAction.plain(actionResume, '재개'),
            DarwinNotificationAction.plain(actionComplete, '완료'),
            DarwinNotificationAction.plain(
              actionCancel,
              '취소',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    _initialized = true;
  }

  // ─── 타이머 알림 메서드 ────────────────────────────────────────────────

  /// 타이머 측정 중 알림 표시.
  /// Android: 크로노미터로 실시간 경과 시간 표시.
  /// iOS: 시작 시각 정적 표시 + 액션 버튼.
  static Future<void> showTimerRunning({
    required DateTime originalStartTime,
    Duration accumulated = Duration.zero,
  }) async {
    // Android 크로노미터 기준 시각: 현재 - 누적 = 전체 경과 시간이 반영된 기준점
    final chronoBase =
        DateTime.now().millisecondsSinceEpoch - accumulated.inMilliseconds;

    final androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      _timerChannelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: chronoBase,
      usesChronometer: true,
      chronometerCountDown: false,
      actions: const [
        AndroidNotificationAction(actionPause, '일시정지'),
        AndroidNotificationAction(actionComplete, '완료'),
        AndroidNotificationAction(actionCancel, '취소'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'TIMER_RUNNING',
    );

    await _plugin.show(
      timerNotifId,
      '⏱ 타임워치 측정 중',
      '${_formatTime(originalStartTime)}부터 시작',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// 타이머 일시정지 알림 표시.
  static Future<void> showTimerPaused({
    required DateTime originalStartTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      _timerChannelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(actionResume, '재개'),
        AndroidNotificationAction(actionComplete, '완료'),
        AndroidNotificationAction(actionCancel, '취소'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'TIMER_PAUSED',
    );

    await _plugin.show(
      timerNotifId,
      '⏸ 타임워치 일시정지',
      '${_formatTime(originalStartTime)}에 시작',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// 타이머 알림 제거.
  static Future<void> cancelTimerNotification() async {
    await _plugin.cancel(timerNotifId);
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $displayH:$m';
  }

  // ─── 매일 알림 메서드 (기존 유지) ────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    } else if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  static Future<void> schedule(
    int hour,
    int minute, {
    required String title,
    required String body,
  }) async {
    await cancel();

    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduled =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        _dailyChannelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _dailyNotifId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(_dailyNotifId);
  }
}
