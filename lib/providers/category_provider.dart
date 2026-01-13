import 'package:flutter/foundation.dart' hide Category;
import 'package:isar/isar.dart';
import '../models/category.dart';
import '../services/isar_service.dart';

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

    final isar = await IsarService.instance;
    _categories = await isar.categorys.where().sortByOrder().findAll();

    _isLoading = false;
    notifyListeners();
  }

  // 카테고리 추가
  Future<void> addCategory(Category category) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    await loadCategories();
  }

  // 카테고리 수정
  Future<void> updateCategory(Category category) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    await loadCategories();
  }

  // 카테고리 삭제
  Future<void> deleteCategory(int id) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
    await loadCategories();
  }
}
