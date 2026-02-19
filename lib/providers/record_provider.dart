import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/daily_record.dart';
import '../services/isar_service.dart';

class RecordProvider extends ChangeNotifier {
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

  RecordProvider() {
    loadRecord(_selectedDate);
    loadMonthRecords(_selectedDate);
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

    final isar = await IsarService.instance;
    final dateString = _formatDate(date);

    _currentRecord = await isar.dailyRecords
        .filter()
        .dateEqualTo(dateString)
        .findFirst();

    // 기록이 없으면 빈 기록 생성
    if (_currentRecord == null) {
      _currentRecord = DailyRecord(
        date: dateString,
        message: null,
        timeRecords: [],
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // 한마디 업데이트
  Future<void> updateMessage(String message) async {
    if (_currentRecord == null) return;

    _currentRecord!.message = message;

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.dailyRecords.put(_currentRecord!);
    });

    notifyListeners();
  }

  // 시간 기록 업데이트
  Future<void> updateTimeRecord(int categoryId, int minutes) async {
    if (_currentRecord == null) return;

    // 기존 timeRecords가 null이면 빈 리스트 생성
    final currentRecords = _currentRecord!.timeRecords ?? [];

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

    _currentRecord!.timeRecords = newRecords;

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.dailyRecords.put(_currentRecord!);
    });

    // 월별 캐시도 업데이트
    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = _currentRecord!;

    notifyListeners();
  }

  // 특정 카테고리의 시간 가져오기
  int getMinutesForCategory(int categoryId) {
    if (_currentRecord?.timeRecords == null) return 0;

    final entry = _currentRecord!.timeRecords!
        .firstWhere(
          (entry) => entry.categoryId == categoryId,
          orElse: () => TimeEntry(categoryId: categoryId, minutes: 0),
        );

    return entry.minutes;
  }

  // 체크박스 완료 여부 확인
  bool isCheckBoxCompleted(int checkBoxId) {
    if (_currentRecord?.checkRecords == null) return false;

    final entry = _currentRecord!.checkRecords!
        .where((entry) => entry.checkBoxId == checkBoxId)
        .firstOrNull;

    return entry?.isCompleted ?? false;
  }

  // 체크박스 토글
  Future<void> toggleCheckBox(int checkBoxId) async {
    if (_currentRecord == null) return;

    final currentRecords = _currentRecord!.checkRecords ?? [];
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

    _currentRecord!.checkRecords = newRecords;

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.dailyRecords.put(_currentRecord!);
    });

    // 월별 캐시도 업데이트
    final dateString = _formatDate(_selectedDate);
    _monthRecords[dateString] = _currentRecord!;

    notifyListeners();
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

    notifyListeners();
  }

  // 특정 날짜의 최다 시간 카테고리 정보 가져오기
  ({int categoryId, int minutes})? getTopCategoryForDate(DateTime date) {
    final dateString = _formatDate(date);
    final record = _monthRecords[dateString];

    if (record == null || record.timeRecords == null || record.timeRecords!.isEmpty) {
      return null;
    }

    // 가장 시간이 많은 카테고리 찾기
    TimeEntry? topEntry;
    for (final entry in record.timeRecords!) {
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
    final record = _monthRecords[dateString];
    if (record?.checkRecords == null) return 0;
    return record!.checkRecords!.where((e) => e.isCompleted).length;
  }

  // ========== 통계 관련 메서드 ==========

  // 기간별 기록 조회 (통계용)
  Future<List<DailyRecord>> getRecordsForDateRange(DateTime start, DateTime end) async {
    final isar = await IsarService.instance;
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    return await isar.dailyRecords
        .filter()
        .dateGreaterThan(startDate, include: true)
        .dateLessThan(endDate, include: true)
        .findAll();
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

      if (record?.timeRecords != null) {
        for (final entry in record!.timeRecords!) {
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

      if (record?.timeRecords != null) {
        for (final entry in record!.timeRecords!) {
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
      if (record.timeRecords != null) {
        for (final entry in record.timeRecords!) {
          totals[entry.categoryId] = (totals[entry.categoryId] ?? 0) + entry.minutes;
        }
      }
    }

    return totals;
  }
}
