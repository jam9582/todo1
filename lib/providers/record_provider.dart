import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import '../models/daily_record.dart';
import '../services/isar_service.dart';
import '../services/widget_service.dart';

class RecordProvider extends ChangeNotifier with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  DailyRecord? _currentRecord;
  bool _isLoading = false;

  // 월별 기록 캐시
  Map<String, DailyRecord> _monthRecords = {};
  String _loadedMonth = '';

  DateTime get selectedDate => _selectedDate;
  DailyRecord? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  Map<String, DailyRecord> get monthRecords => _monthRecords;
  bool get isCurrentRestDay => _currentRecord?.isRestDay ?? false;
  bool get isFutureDate {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isAfter(todayDate);
  }

  RecordProvider() {
    WidgetsBinding.instance.addObserver(this);
    loadRecord(_selectedDate);
    loadMonthRecords(_selectedDate);
    processWidgetPendingCompletion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      processWidgetPendingCompletion();
    }
  }

  /// 위젯에서 완료된 타이머 기록이 있으면 Isar에 저장
  Future<void> processWidgetPendingCompletion() async {
    final pending = await WidgetService.popPendingCompletion();
    if (pending == null) return;
    await updateTimeRecordForToday(pending.categoryId, pending.minutes);
  }

  // 날짜 선택
  void selectDate(DateTime date) {
    final monthChanged = _selectedDate.year != date.year || _selectedDate.month != date.month;
    _selectedDate = date;
    loadRecord(date);
    if (monthChanged) {
      loadMonthRecords(date);
    }
  }

  // 특정 날짜의 기록 불러오기
  Future<void> loadRecord(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isar = await IsarService.instance;
      final dateString = _formatDate(date);

      _currentRecord = await isar.dailyRecords
          .filter()
          .dateEqualTo(dateString)
          .findFirst();
    } catch (e) {
      debugPrint('기록 로드 실패: $e');
    }

    // 기록이 없으면 빈 기록 생성
    _currentRecord ??= DailyRecord(
      date: _formatDate(date),
      message: null,
      timeRecords: [],
    );

    _isLoading = false;
    notifyListeners();
  }

  // 한마디 업데이트
  Future<void> updateMessage(String message) async {
    final record = _currentRecord;
    if (record == null) return;

    record.message = message;

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('메시지 저장 실패: $e');
    }

    notifyListeners();
  }

  // 시간 기록 업데이트
  Future<void> updateTimeRecord(int categoryId, int minutes) async {
    final record = _currentRecord;
    if (record == null) return;

    // 기존 timeRecords가 null이면 빈 리스트 생성
    final currentRecords = record.timeRecords ?? [];

    // 해당 카테고리의 기록 찾기
    final index = currentRecords.indexWhere((entry) => entry.categoryId == categoryId);

    // 새 리스트 생성 (Isar embedded 객체 변경 감지를 위해)
    List<TimeEntry> newRecords;
    if (index != -1) {
      // 기존 기록 업데이트
      newRecords = currentRecords.map((entry) {
        if (entry.categoryId == categoryId) {
          return TimeEntry(categoryId: categoryId, minutes: minutes);
        }
        return entry;
      }).toList();
    } else {
      // 새 기록 추가
      newRecords = [
        ...currentRecords,
        TimeEntry(categoryId: categoryId, minutes: minutes),
      ];
    }

    record.timeRecords = newRecords;

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('시간 기록 저장 실패: $e');
    }

    // 월별 캐시도 업데이트
    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = record;

    notifyListeners();
  }

  // 특정 카테고리의 시간 가져오기
  int getMinutesForCategory(int categoryId) {
    final timeRecords = _currentRecord?.timeRecords;
    if (timeRecords == null) return 0;

    final entry = timeRecords
        .firstWhere(
          (entry) => entry.categoryId == categoryId,
          orElse: () => TimeEntry(categoryId: categoryId, minutes: 0),
        );

    return entry.minutes;
  }

  // 체크박스 완료 여부 확인
  bool isCheckBoxCompleted(int checkBoxId) {
    final checkRecords = _currentRecord?.checkRecords;
    if (checkRecords == null) return false;

    final entry = checkRecords
        .where((entry) => entry.checkBoxId == checkBoxId)
        .firstOrNull;

    return entry?.isCompleted ?? false;
  }

  // 체크박스 토글
  Future<void> toggleCheckBox(int checkBoxId) async {
    final record = _currentRecord;
    if (record == null) return;

    final currentRecords = record.checkRecords ?? [];
    final currentStatus = isCheckBoxCompleted(checkBoxId);

    // 해당 체크박스의 기록 찾기
    final index = currentRecords.indexWhere((entry) => entry.checkBoxId == checkBoxId);

    List<CheckEntry> newRecords;
    if (index != -1) {
      // 기존 기록 토글
      newRecords = currentRecords.map((entry) {
        if (entry.checkBoxId == checkBoxId) {
          return CheckEntry(checkBoxId: checkBoxId, isCompleted: !currentStatus);
        }
        return entry;
      }).toList();
    } else {
      // 새 기록 추가 (체크됨으로)
      newRecords = [
        ...currentRecords,
        CheckEntry(checkBoxId: checkBoxId, isCompleted: true),
      ];
    }

    record.checkRecords = newRecords;

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('체크박스 저장 실패: $e');
    }

    // 월별 캐시도 업데이트
    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = record;

    notifyListeners();
  }

  // 쉬는 날 활성화 (메시지 자동 입력 포함)
  Future<void> activateRestDay(String message) async {
    final record = _currentRecord;
    if (record == null) return;

    record.isRestDay = true;
    record.message = message;

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('쉬는 날 활성화 실패: $e');
    }

    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = record;

    notifyListeners();
  }

  // 쉬는 날 해제 (메시지도 함께 초기화)
  Future<void> deactivateRestDay() async {
    final record = _currentRecord;
    if (record == null) return;

    record.isRestDay = false;
    record.message = null;

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('쉬는 날 해제 실패: $e');
    }

    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = record;

    notifyListeners();
  }

  // 쉬는 날 토글
  Future<void> toggleRestDay() async {
    final record = _currentRecord;
    if (record == null) return;

    record.isRestDay = !(record.isRestDay);

    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.dailyRecords.put(record);
      });
    } catch (e) {
      debugPrint('쉬는 날 토글 실패: $e');
    }

    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = record;

    notifyListeners();
  }

  // 특정 날짜 쉬는 날 여부
  bool getIsRestDayForDate(DateTime date) {
    final dateString = _formatDate(date);
    return _monthRecords[dateString]?.isRestDay ?? false;
  }

  // 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 월 포맷팅 (YYYY-MM)
  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // 월별 기록 로드
  Future<void> loadMonthRecords(DateTime month) async {
    final monthKey = _formatMonth(month);

    // 이미 로드된 월이면 스킵
    if (_loadedMonth == monthKey) return;

    try {
      final isar = await IsarService.instance;

      // 해당 월의 시작일과 종료일
      final startDate = _formatDate(DateTime(month.year, month.month, 1));
      final endDate = _formatDate(DateTime(month.year, month.month + 1, 0));

      // 해당 월의 모든 기록 조회
      final records = await isar.dailyRecords
          .filter()
          .dateGreaterThan(startDate, include: true)
          .dateLessThan(endDate, include: true)
          .findAll();

      // Map으로 변환
      _monthRecords = {
        for (var record in records) record.date: record
      };
      _loadedMonth = monthKey;
    } catch (e) {
      debugPrint('월별 기록 로드 실패: $e');
    }

    notifyListeners();
  }

  // 특정 날짜의 최다 시간 카테고리 정보 가져오기
  ({int categoryId, int minutes})? getTopCategoryForDate(DateTime date) {
    final dateString = _formatDate(date);
    final timeRecords = _monthRecords[dateString]?.timeRecords;

    if (timeRecords == null || timeRecords.isEmpty) {
      return null;
    }

    // 가장 시간이 많은 카테고리 찾기
    TimeEntry? topEntry;
    for (final entry in timeRecords) {
      if (entry.minutes > 0) {
        if (topEntry == null || entry.minutes > topEntry.minutes) {
          topEntry = entry;
        }
      }
    }

    if (topEntry == null) return null;

    return (categoryId: topEntry.categoryId, minutes: topEntry.minutes);
  }

  // 특정 날짜의 완료된 체크박스 개수 가져오기 (달력 표시용)
  int getCompletedCheckCountForDate(DateTime date) {
    final dateString = _formatDate(date);
    final checkRecords = _monthRecords[dateString]?.checkRecords;
    if (checkRecords == null) return 0;
    return checkRecords.where((e) => e.isCompleted).length;
  }

  // 특정 날짜의 특정 카테고리 활동시간 가져오기 (달력 고정 카테고리 모드용)
  ({int categoryId, int minutes})? getCategoryForDate(DateTime date, int categoryId) {
    final dateString = _formatDate(date);
    final timeRecords = _monthRecords[dateString]?.timeRecords;
    if (timeRecords == null) return null;
    final entry = timeRecords
        .where((e) => e.categoryId == categoryId && e.minutes > 0)
        .firstOrNull;
    if (entry == null) return null;
    return (categoryId: entry.categoryId, minutes: entry.minutes);
  }

  // 오늘 날짜 기록에 시간 추가 (타이머 완료 시 사용)
  Future<void> updateTimeRecordForToday(int categoryId, int minutes) async {
    if (minutes <= 0) return;
    final today = DateTime.now();
    final todayString = _formatDate(today);

    try {
      final isar = await IsarService.instance;

      // 오늘의 기록 로드 (없으면 생성)
      final todayRecord = await isar.dailyRecords
          .filter()
          .dateEqualTo(todayString)
          .findFirst() ?? DailyRecord(date: todayString, timeRecords: []);

      // timeRecords 업데이트
      final currentRecords = todayRecord.timeRecords ?? [];
      final index = currentRecords.indexWhere((e) => e.categoryId == categoryId);

      List<TimeEntry> newRecords;
      if (index != -1) {
        newRecords = currentRecords.map((e) {
          if (e.categoryId == categoryId) {
            return TimeEntry(categoryId: categoryId, minutes: e.minutes + minutes);
          }
          return e;
        }).toList();
      } else {
        newRecords = [...currentRecords, TimeEntry(categoryId: categoryId, minutes: minutes)];
      }

      todayRecord.timeRecords = newRecords;

      await isar.writeTxn(() async {
        await isar.dailyRecords.put(todayRecord);
      });

      // selectedDate가 오늘이면 _currentRecord도 업데이트
      final selectedString = _formatDate(_selectedDate);
      if (selectedString == todayString) {
        _currentRecord = todayRecord;
      }
      _monthRecords[todayString] = todayRecord;

      // 위젯 오늘 활동시간 동기화
      final todayMinutes = {
        for (final e in todayRecord.timeRecords ?? <TimeEntry>[])
          e.categoryId: e.minutes,
      };
      WidgetService.updateTodayMinutes(todayMinutes);
    } catch (e) {
      debugPrint('오늘 시간 기록 저장 실패: $e');
    }

    notifyListeners();
  }

  // ========== 통계 관련 메서드 ==========

  // 기간별 기록 조회 (통계용)
  Future<List<DailyRecord>> getRecordsForDateRange(DateTime start, DateTime end) async {
    try {
      final isar = await IsarService.instance;
      final startDate = _formatDate(start);
      final endDate = _formatDate(end);

      return await isar.dailyRecords
          .filter()
          .dateGreaterThan(startDate, include: true)
          .dateLessThan(endDate, include: true)
          .findAll();
    } catch (e) {
      debugPrint('기간별 기록 조회 실패: $e');
      return [];
    }
  }

  // 주간 통계 데이터 (최근 7일)
  Future<Map<String, List<({DateTime date, int minutes})>>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: 6)); // 7일 전부터

    final records = await getRecordsForDateRange(weekStart, now);

    // 카테고리별 일일 데이터 맵
    final Map<String, List<({DateTime date, int minutes})>> categoryData = {};

    // 7일간의 날짜 리스트 생성
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateString = _formatDate(date);
      final record = records.where((r) => r.date == dateString).firstOrNull;

      final timeRecords = record?.timeRecords;
      if (record?.isRestDay != true && timeRecords != null) {
        for (final entry in timeRecords) {
          if (entry.minutes > 0) {
            final key = entry.categoryId.toString();
            categoryData.putIfAbsent(key, () => []);
            categoryData[key]!.add((date: date, minutes: entry.minutes));
          }
        }
      }
    }

    return categoryData;
  }

  // 월간 통계 데이터 (이번 달)
  Future<Map<String, List<({DateTime date, int minutes})>>> getMonthlyStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final records = await getRecordsForDateRange(monthStart, monthEnd);

    final Map<String, List<({DateTime date, int minutes})>> categoryData = {};

    // 해당 월의 모든 날짜
    for (int day = 1; day <= monthEnd.day; day++) {
      final date = DateTime(now.year, now.month, day);
      if (date.isAfter(now)) break; // 오늘 이후는 스킵

      final dateString = _formatDate(date);
      final record = records.where((r) => r.date == dateString).firstOrNull;

      final timeRecords = record?.timeRecords;
      if (record?.isRestDay != true && timeRecords != null) {
        for (final entry in timeRecords) {
          if (entry.minutes > 0) {
            final key = entry.categoryId.toString();
            categoryData.putIfAbsent(key, () => []);
            categoryData[key]!.add((date: date, minutes: entry.minutes));
          }
        }
      }
    }

    return categoryData;
  }

  // 기간별 카테고리 총합 (프로그레스 바용)
  Future<Map<int, int>> getCategoryTotals(DateTime start, DateTime end) async {
    final records = await getRecordsForDateRange(start, end);

    final Map<int, int> totals = {};

    for (final record in records) {
      if (record.isRestDay) continue;
      final timeRecords = record.timeRecords;
      if (timeRecords != null) {
        for (final entry in timeRecords) {
          totals[entry.categoryId] = (totals[entry.categoryId] ?? 0) + entry.minutes;
        }
      }
    }

    return totals;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
