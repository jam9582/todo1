import 'package:flutter/foundation.dart' hide Category;
import 'package:isar/isar.dart';
import '../models/category.dart';
import '../models/daily_record.dart';
import '../services/isar_service.dart';
import '../services/widget_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    loadCategories();
  }

  // 카테고리 목록 불러오기
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isar = await IsarService.instance;
      _categories = await isar.categorys.where().sortByOrder().findAll();
    } catch (e) {
      debugPrint('카테고리 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
    WidgetService.updateCategories(_categories);
  }

  // 카테고리 추가
  Future<void> addCategory(Category category) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.categorys.put(category);
      });
    } catch (e) {
      debugPrint('카테고리 추가 실패: $e');
    }
    await loadCategories();
  }

  // 카테고리 수정
  Future<void> updateCategory(Category category) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.categorys.put(category);
      });
    } catch (e) {
      debugPrint('카테고리 수정 실패: $e');
    }
    await loadCategories();
  }

  // 카테고리 삭제 (연관된 시간 기록도 함께 정리)
  Future<void> deleteCategory(int id) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.categorys.delete(id);
        // 연관된 TimeEntry 정리
        final records = await isar.dailyRecords.where().findAll();
        for (final record in records) {
          final entries = record.timeRecords;
          if (entries == null) continue;
          final filtered = entries.where((e) => e.categoryId != id).toList();
          if (filtered.length != entries.length) {
            record.timeRecords = filtered.isEmpty ? null : filtered;
            await isar.dailyRecords.put(record);
          }
        }
      });
    } catch (e) {
      debugPrint('카테고리 삭제 실패: $e');
    }
    await loadCategories();
  }
}
