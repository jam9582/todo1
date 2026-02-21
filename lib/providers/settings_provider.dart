import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

enum CalendarStartDay { sunday, monday }

enum CalendarDisplayMode { topCategory, fixedCategory }

class SettingsProvider extends ChangeNotifier {
  static const _keyStartDay = 'start_day';
  static const _keyNotifEnabled = 'notif_enabled';
  static const _keyNotifHour = 'notif_hour';
  static const _keyNotifMinute = 'notif_minute';
  static const _keyDisplayMode = 'display_mode';
  static const _keyFixedCategoryId = 'fixed_category_id';
  static const _keyShowActivityTime = 'show_activity_time';
  static const _keyShowCheckCount = 'show_check_count';

  SharedPreferences? _prefs;

  CalendarStartDay get startDay =>
      (_prefs?.getInt(_keyStartDay) ?? 0) == 0
          ? CalendarStartDay.sunday
          : CalendarStartDay.monday;

  bool get notifEnabled => _prefs?.getBool(_keyNotifEnabled) ?? false;
  int get notifHour => _prefs?.getInt(_keyNotifHour) ?? 21;
  int get notifMinute => _prefs?.getInt(_keyNotifMinute) ?? 0;

  CalendarDisplayMode get displayMode =>
      (_prefs?.getInt(_keyDisplayMode) ?? 0) == 0
          ? CalendarDisplayMode.topCategory
          : CalendarDisplayMode.fixedCategory;

  int? get fixedCategoryId => _prefs?.getInt(_keyFixedCategoryId);
  bool get showActivityTime => _prefs?.getBool(_keyShowActivityTime) ?? true;
  bool get showCheckCount => _prefs?.getBool(_keyShowCheckCount) ?? true;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  Future<void> setStartDay(CalendarStartDay d) async {
    await _prefs?.setInt(_keyStartDay, d == CalendarStartDay.sunday ? 0 : 1);
    notifyListeners();
  }

  Future<void> setNotifEnabled(
    bool v, {
    required String notifTitle,
    required String notifBody,
  }) async {
    if (v) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return;
      await NotificationService.schedule(
        notifHour,
        notifMinute,
        title: notifTitle,
        body: notifBody,
      );
    } else {
      await NotificationService.cancel();
    }
    await _prefs?.setBool(_keyNotifEnabled, v);
    notifyListeners();
  }

  Future<void> setNotifTime(
    int h,
    int m, {
    required String notifTitle,
    required String notifBody,
  }) async {
    await _prefs?.setInt(_keyNotifHour, h);
    await _prefs?.setInt(_keyNotifMinute, m);
    if (notifEnabled) {
      await NotificationService.schedule(
        h,
        m,
        title: notifTitle,
        body: notifBody,
      );
    }
    notifyListeners();
  }

  Future<void> setDisplayMode(CalendarDisplayMode m) async {
    await _prefs?.setInt(
        _keyDisplayMode, m == CalendarDisplayMode.topCategory ? 0 : 1);
    notifyListeners();
  }

  Future<void> setFixedCategoryId(int? id) async {
    if (id == null) {
      await _prefs?.remove(_keyFixedCategoryId);
    } else {
      await _prefs?.setInt(_keyFixedCategoryId, id);
    }
    notifyListeners();
  }

  Future<void> setShowActivityTime(bool v) async {
    await _prefs?.setBool(_keyShowActivityTime, v);
    notifyListeners();
  }

  Future<void> setShowCheckCount(bool v) async {
    await _prefs?.setBool(_keyShowCheckCount, v);
    notifyListeners();
  }
}
