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

    notifyListeners();
  }

  // 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
