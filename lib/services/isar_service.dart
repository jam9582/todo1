import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';
import '../models/check_box.dart';
import '../models/daily_record.dart';

class IsarService {
  static Isar? _isar;

  // Isar 인스턴스 가져오기
  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CategorySchema, CheckBoxSchema, DailyRecordSchema],
      directory: dir.path,
    );

    // 첫 실행 시 기본 카테고리 생성
    await _initializeDefaultCategories();

    return _isar!;
  }

  // 기본 카테고리 초기화
  static Future<void> _initializeDefaultCategories() async {
    final isar = _isar!;

    // 이미 카테고리가 있으면 스킵
    final count = await isar.categorys.count();
    if (count > 0) return;

    // 기본 4개 카테고리 생성
    final defaultCategories = [
      Category(emoji: '☕', name: '공부', order: 0),
      Category(emoji: '🌙', name: '운동', order: 1),
      Category(emoji: '💼', name: '업무', order: 2),
      Category(emoji: '🎧', name: '청소', order: 3),
    ];

    await isar.writeTxn(() async {
      await isar.categorys.putAll(defaultCategories);
    });
  }

  // DB 닫기
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
