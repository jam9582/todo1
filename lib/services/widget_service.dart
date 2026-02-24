import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/category.dart';

/// 홈 화면 위젯에 데이터를 동기화하는 서비스.
/// 위젯이 없거나 home_widget 초기화 실패 시에도 조용히 무시.
class WidgetService {
  static const _androidWidgetSmall = 'TimerWidgetSmall';
  static const _androidWidgetMedium = 'TimerWidgetMedium';
  static const _androidWidgetLarge = 'TimerWidgetLarge';

  // 앱의 카테고리 색상 팔레트 (통계 화면과 동일)
  static const categoryColorHexes = [
    '#E8A87C', // 웜 오렌지
    '#85C1E9', // 소프트 블루
    '#82E0AA', // 소프트 그린
    '#C39BD3', // 소프트 퍼플
  ];

  // 내부 캐시 — 카테고리/시간 중 어느 하나가 바뀌어도 전체 sync 가능
  static List<Category> _cachedCategories = [];
  static Map<int, int> _cachedTodayMinutes = {};

  // ─── Flutter → 위젯 데이터 동기화 ────────────────────────────────────

  static Future<void> updateCategories(List<Category> categories) async {
    _cachedCategories = categories;
    await _syncCategoriesData();
  }

  static Future<void> updateTodayMinutes(Map<int, int> minutesByCategoryId) async {
    _cachedTodayMinutes = minutesByCategoryId;
    await _syncCategoriesData();
  }

  static Future<void> _syncCategoriesData() async {
    try {
      final capped = _cachedCategories.take(4).toList();
      final data = List.generate(capped.length, (i) => {
        'id': capped[i].id,
        'name': capped[i].name,
        'emoji': capped[i].emoji,
        'colorIndex': i,
        'todayMinutes': _cachedTodayMinutes[capped[i].id] ?? 0,
      });
      await HomeWidget.saveWidgetData<String>(
          'widget_categories', json.encode(data));
      await _updateAllWidgets();
    } catch (_) {}
  }

  // ─── 타이머 상태 위젯 동기화 ──────────────────────────────────────────

  /// 타이머 시작 (카테고리 있음 — 위젯에서 시작한 경우)
  static Future<void> syncTimerStarted({
    required int categoryId,
    required String categoryName,
    required String categoryEmoji,
    required int colorIndex,
    required DateTime originalStartTime,
  }) async {
    try {
      final data = {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryEmoji': categoryEmoji,
        'colorIndex': colorIndex,
        'originalStartTime': originalStartTime.toIso8601String(),
        'isPaused': false,
      };
      await HomeWidget.saveWidgetData<String>(
          'widget_timer', json.encode(data));
      await _updateAllWidgets();
    } catch (_) {}
  }

  /// 타이머 시작 (카테고리 없음 — 앱에서 바로 시작한 경우)
  static Future<void> syncTimerStartedNoCategory({
    required DateTime originalStartTime,
  }) async {
    try {
      final data = {
        'categoryId': -1,
        'categoryName': '',
        'categoryEmoji': '',
        'colorIndex': -1,
        'originalStartTime': originalStartTime.toIso8601String(),
        'isPaused': false,
      };
      await HomeWidget.saveWidgetData<String>(
          'widget_timer', json.encode(data));
      await _updateAllWidgets();
    } catch (_) {}
  }

  static Future<void> syncTimerPaused() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_timer');
      if (raw == null) return;
      final data = json.decode(raw) as Map<String, dynamic>;
      data['isPaused'] = true;
      await HomeWidget.saveWidgetData<String>(
          'widget_timer', json.encode(data));
      await _updateAllWidgets();
    } catch (_) {}
  }

  static Future<void> syncTimerResumed() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_timer');
      if (raw == null) return;
      final data = json.decode(raw) as Map<String, dynamic>;
      data['isPaused'] = false;
      await HomeWidget.saveWidgetData<String>(
          'widget_timer', json.encode(data));
      await _updateAllWidgets();
    } catch (_) {}
  }

  static Future<void> syncTimerCleared() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_timer', null);
      await _updateAllWidgets();
    } catch (_) {}
  }

  // ─── 위젯 → 앱 완료 기록 처리 ─────────────────────────────────────────

  /// 위젯에서 완료된 타이머 기록을 읽고 삭제. 없으면 null 반환.
  static Future<({int categoryId, int minutes})?> popPendingCompletion() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(
          'widget_pending_completion');
      if (raw == null) return null;
      await HomeWidget.saveWidgetData<String>(
          'widget_pending_completion', null);
      final data = json.decode(raw) as Map<String, dynamic>;
      final categoryId = data['categoryId'] as int?;
      final minutes = data['minutes'] as int?;
      if (categoryId == null || minutes == null || minutes <= 0) return null;
      return (categoryId: categoryId, minutes: minutes);
    } catch (_) {
      return null;
    }
  }

  // ─── 앱 재시작 시 위젯 카테고리 정보 읽기 ─────────────────────────────

  /// 위젯에서 시작한 타이머의 카테고리 정보 읽기.
  static Future<Map<String, dynamic>?> getWidgetTimerData() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_timer');
      if (raw == null) return null;
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _updateAllWidgets() async {
    await HomeWidget.updateWidget(androidName: _androidWidgetSmall);
    await HomeWidget.updateWidget(androidName: _androidWidgetMedium);
    await HomeWidget.updateWidget(androidName: _androidWidgetLarge);
  }
}
