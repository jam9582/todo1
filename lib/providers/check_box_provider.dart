import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/check_box.dart';
import '../services/isar_service.dart';

class CheckBoxProvider extends ChangeNotifier {
  List<CheckBox> _checkBoxes = [];
  bool _isLoading = false;

  List<CheckBox> get checkBoxes => _checkBoxes;
  bool get isLoading => _isLoading;

  CheckBoxProvider() {
    loadCheckBoxes();
  }

  // 체크박스 목록 불러오기
  Future<void> loadCheckBoxes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isar = await IsarService.instance;
      _checkBoxes = await isar.checkBoxs.where().sortByOrder().findAll();
    } catch (e) {
      debugPrint('체크박스 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 체크박스 추가
  Future<void> addCheckBox(CheckBox checkBox) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.checkBoxs.put(checkBox);
      });
    } catch (e) {
      debugPrint('체크박스 추가 실패: $e');
    }
    await loadCheckBoxes();
  }

  // 체크박스 수정
  Future<void> updateCheckBox(CheckBox checkBox) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.checkBoxs.put(checkBox);
      });
    } catch (e) {
      debugPrint('체크박스 수정 실패: $e');
    }
    await loadCheckBoxes();
  }

  // 체크박스 삭제
  Future<void> deleteCheckBox(int id) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.checkBoxs.delete(id);
      });
    } catch (e) {
      debugPrint('체크박스 삭제 실패: $e');
    }
    await loadCheckBoxes();
  }

  // 순서 업데이트
  Future<void> reorderCheckBoxes(List<CheckBox> reorderedList) async {
    try {
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        for (int i = 0; i < reorderedList.length; i++) {
          reorderedList[i].order = i;
          await isar.checkBoxs.put(reorderedList[i]);
        }
      });
    } catch (e) {
      debugPrint('체크박스 순서 변경 실패: $e');
    }
    await loadCheckBoxes();
  }
}
