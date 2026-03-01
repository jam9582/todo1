import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../l10n/app_localizations.dart';

/// 앱이 완전히 종료된 상태에서 알림 액션 버튼을 눌렀을 때 호출되는 핸들러.
/// 별도 isolate에서 실행되므로 SharedPreferences에 명령을 저장하고 종료.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  final actionId = response.actionId;
  if (response.id == NotificationService.timerNotifId && actionId != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotificationService.keyPendingAction, actionId);
  }
}

class NotificationService {
  // ─── 매일 알림 ──────────────────────────────────────────────────────────
  static const _dailyChannelId = 'todo1_daily';
  static const _dailyNotifId = 0;

  // ─── 타이머 알림 ─────────────────────────────────────────────────────────
  static const _timerChannelId = 'todo1_timer';
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

  // l10n 캐시 — initialize() 시 로드, 언어 변경 시 refreshLocale()로 갱신
  static AppLocalizations? _l10n;

  /// 앱이 살아있을 때 타이머 액션 버튼 처리 콜백 (TimerProvider가 등록)
  static void Function(String actionId)? _timerActionHandler;

  static void setTimerActionHandler(void Function(String actionId) handler) {
    _timerActionHandler = handler;
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (response.id == timerNotifId && actionId != null) {
      _timerActionHandler?.call(actionId);
    }
  }

  /// 사용자가 언어를 변경했을 때 호출하여 l10n 캐시 갱신
  static Future<void> refreshLocale() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _l10n = await AppLocalizations.delegate.load(locale);
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    // l10n 로드
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _l10n = await AppLocalizations.delegate.load(locale);

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    final l10n = _l10n!;

    // iOS: 타이머 측정 중 / 일시정지 두 가지 카테고리 등록
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'TIMER_RUNNING',
          actions: [
            DarwinNotificationAction.plain(actionPause, l10n.notifActionPause),
            DarwinNotificationAction.plain(actionComplete, l10n.notifActionComplete),
            DarwinNotificationAction.plain(
              actionCancel,
              l10n.notifActionCancel,
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          'TIMER_PAUSED',
          actions: [
            DarwinNotificationAction.plain(actionResume, l10n.notifActionResume),
            DarwinNotificationAction.plain(actionComplete, l10n.notifActionComplete),
            DarwinNotificationAction.plain(
              actionCancel,
              l10n.notifActionCancel,
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
    final l10n = _l10n;
    if (l10n == null) return;

    // Android 크로노미터 기준 시각: 현재 - 누적 = 전체 경과 시간이 반영된 기준점
    final chronoBase =
        DateTime.now().millisecondsSinceEpoch - accumulated.inMilliseconds;

    final androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      l10n.notifTimerChannel,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: chronoBase,
      usesChronometer: true,
      chronometerCountDown: false,
      actions: [
        AndroidNotificationAction(actionPause, l10n.notifActionPause),
        AndroidNotificationAction(actionComplete, l10n.notifActionComplete),
        AndroidNotificationAction(actionCancel, l10n.notifActionCancel),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'TIMER_RUNNING',
    );

    await _plugin.show(
      timerNotifId,
      l10n.notifTimerRunning,
      l10n.notifTimerStartedFrom(_formatTime(originalStartTime, l10n)),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// 타이머 일시정지 알림 표시.
  static Future<void> showTimerPaused({
    required DateTime originalStartTime,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;

    final androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      l10n.notifTimerChannel,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(actionResume, l10n.notifActionResume),
        AndroidNotificationAction(actionComplete, l10n.notifActionComplete),
        AndroidNotificationAction(actionCancel, l10n.notifActionCancel),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'TIMER_PAUSED',
    );

    await _plugin.show(
      timerNotifId,
      l10n.notifTimerPaused,
      l10n.notifTimerStartedAt(_formatTime(originalStartTime, l10n)),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// 타이머 알림 제거.
  static Future<void> cancelTimerNotification() async {
    await _plugin.cancel(timerNotifId);
  }

  static String _formatTime(DateTime dt, AppLocalizations l10n) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? l10n.timeAm : l10n.timePm;
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

    final l10n = _l10n;

    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduled =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        l10n?.notifChannelName ?? 'Daily Reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
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
