import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/daily_record.dart';
import '../services/isar_service.dart';

class RecordProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DailyRecord? _currentRecord;
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  DailyRecord? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;

  RecordProvider() {
    loadRecord(_selectedDate);
  }

  // 날짜 선택
  void selectDate(DateTime date) {
    _selectedDate = date;
    loadRecord(date);
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
    _currentRecord!.timeRecords ??= [];

    // 해당 카테고리의 기록 찾기
    final index = _currentRecord!.timeRecords!
        .indexWhere((entry) => entry.categoryId == categoryId);

    if (index != -1) {
      // 기존 기록 업데이트
      _currentRecord!.timeRecords![index].minutes = minutes;
    } else {
      // 새 기록 추가
      _currentRecord!.timeRecords!.add(
        TimeEntry(categoryId: categoryId, minutes: minutes),
      );
    }

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.dailyRecords.put(_currentRecord!);
    });

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

  // 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
