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

    final isar = await IsarService.instance;
    _checkBoxes = await isar.checkBoxs.where().sortByOrder().findAll();

    _isLoading = false;
    notifyListeners();
  }

  // 체크박스 추가
  Future<void> addCheckBox(CheckBox checkBox) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.checkBoxs.put(checkBox);
    });
    await loadCheckBoxes();
  }

  // 체크박스 수정
  Future<void> updateCheckBox(CheckBox checkBox) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.checkBoxs.put(checkBox);
    });
    await loadCheckBoxes();
  }

  // 체크박스 삭제
  Future<void> deleteCheckBox(int id) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.checkBoxs.delete(id);
    });
    await loadCheckBoxes();
  }

  // 순서 업데이트
  Future<void> reorderCheckBoxes(List<CheckBox> reorderedList) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      for (int i = 0; i < reorderedList.length; i++) {
        reorderedList[i].order = i;
        await isar.checkBoxs.put(reorderedList[i]);
      }
    });
    await loadCheckBoxes();
  }
}
