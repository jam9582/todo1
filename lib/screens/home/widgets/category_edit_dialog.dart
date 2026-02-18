import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import '../../../constants/colors.dart';
import '../../../models/category.dart';
import '../../../models/check_box.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/check_box_provider.dart';

/// 카테고리 편집 다이얼로그
class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const CategoryEditDialog(),
    );
  }

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  List<Category> _categories = [];
  List<CheckBox> _checkBoxes = [];
  int _selectedTabIndex = 0; // 0: 카테고리, 1: 체크박스

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCheckBoxes();
  }

  void _loadCategories() {
    final provider = context.read<CategoryProvider>();
    setState(() {
      _categories = List.from(provider.categories);
    });
  }

  void _loadCheckBoxes() {
    final provider = context.read<CheckBoxProvider>();
    setState(() {
      _checkBoxes = List.from(provider.checkBoxes);
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // 순서 업데이트
    final provider = context.read<CategoryProvider>();
    for (int i = 0; i < _categories.length; i++) {
      _categories[i].order = i;
      await provider.updateCategory(_categories[i]);
    }
  }

  Future<void> _onEditCategory(Category category) async {
    final result = await _CategoryItemEditDialog.show(context, category: category);
    if (result != null && mounted) {
      final provider = context.read<CategoryProvider>();
      category.emoji = result.emoji;
      category.name = result.name;
      await provider.updateCategory(category);
      _loadCategories();
    }
  }

  Future<void> _onDeleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('카테고리 삭제'),
        content: Text('\'${category.name}\' 카테고리를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.grey500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<CategoryProvider>();
      await provider.deleteCategory(category.id);
      _loadCategories();
    }
  }

  static const int _maxCategories = 4;
  static const int _maxCheckBoxes = 4;
  static const double _itemHeight = 56.0; // IconButton(48) + margin(8)

  // 체크박스 관련 메서드
  Future<void> _onCheckBoxReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _checkBoxes.removeAt(oldIndex);
      _checkBoxes.insert(newIndex, item);
    });

    final provider = context.read<CheckBoxProvider>();
    for (int i = 0; i < _checkBoxes.length; i++) {
      _checkBoxes[i].order = i;
      await provider.updateCheckBox(_checkBoxes[i]);
    }
  }

  Future<void> _onEditCheckBox(CheckBox checkBox) async {
    final result = await _CheckBoxItemEditDialog.show(context, checkBox: checkBox);
    if (result != null && mounted) {
      final provider = context.read<CheckBoxProvider>();
      checkBox.name = result;
      await provider.updateCheckBox(checkBox);
      _loadCheckBoxes();
    }
  }

  Future<void> _onDeleteCheckBox(CheckBox checkBox) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('체크박스 삭제'),
        content: Text('\'${checkBox.name}\' 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.grey500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<CheckBoxProvider>();
      await provider.deleteCheckBox(checkBox.id);
      _loadCheckBoxes();
    }
  }

  Future<void> _onAddCheckBox() async {
    if (_checkBoxes.length >= _maxCheckBoxes) return;

    final result = await _CheckBoxItemEditDialog.show(context);
    if (result != null && mounted) {
      final provider = context.read<CheckBoxProvider>();
      final newCheckBox = CheckBox(
        name: result,
        order: _checkBoxes.length,
      );
      await provider.addCheckBox(newCheckBox);
      _loadCheckBoxes();
    }
  }

  Future<void> _onAddCategory() async {
    if (_categories.length >= _maxCategories) return;

    final result = await _CategoryItemEditDialog.show(context);
    if (result != null && mounted) {
      final provider = context.read<CategoryProvider>();
      final newCategory = Category(
        emoji: result.emoji,
        name: result.name,
        order: _categories.length,
      );
      await provider.addCategory(newCategory);
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_selectedTabIndex == 0) ...[
              Flexible(child: _buildCategoryList()),
              const SizedBox(height: 16),
              _buildAddButton(),
            ] else ...[
              Flexible(child: _buildCheckBoxList()),
              const SizedBox(height: 16),
              _buildCheckBoxAddButton(),
            ],
            const SizedBox(height: 16),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '카테고리',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTabIndex == 0 ? AppColors.textPrimary : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '체크박스',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTabIndex == 1 ? AppColors.textPrimary : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: _itemHeight * _maxCategories,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: _categories.length,
        onReorder: _onReorder,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryItem(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category category, int index) {
    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 드래그 핸들
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.drag_handle_rounded,
                color: AppColors.grey400,
                size: 20,
              ),
            ),
          ),
          // 이모지 & 이름
          Expanded(
            child: Row(
              children: [
                Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 편집 버튼
          IconButton(
            onPressed: () => _onEditCategory(category),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.grey500,
            ),
          ),
          // 삭제 버튼
          IconButton(
            onPressed: () => _onDeleteCategory(category),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBoxList() {
    if (_checkBoxes.isEmpty) {
      return SizedBox(
        height: _itemHeight * _maxCheckBoxes,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_box_outline_blank_rounded,
                size: 48,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 12),
              Text(
                '체크박스를 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: _itemHeight * _maxCheckBoxes,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: _checkBoxes.length,
        onReorder: _onCheckBoxReorder,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final checkBox = _checkBoxes[index];
          return _buildCheckBoxItem(checkBox, index);
        },
      ),
    );
  }

  Widget _buildCheckBoxItem(CheckBox checkBox, int index) {
    return Container(
      key: ValueKey(checkBox.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 드래그 핸들
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.drag_handle_rounded,
                color: AppColors.grey400,
                size: 20,
              ),
            ),
          ),
          // 체크박스 아이콘 & 이름
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: AppColors.grey400,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    checkBox.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 편집 버튼
          IconButton(
            onPressed: () => _onEditCheckBox(checkBox),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.grey500,
            ),
          ),
          // 삭제 버튼
          IconButton(
            onPressed: () => _onDeleteCheckBox(checkBox),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBoxAddButton() {
    final isMaxReached = _checkBoxes.length >= _maxCheckBoxes;

    return GestureDetector(
      onTap: isMaxReached ? null : _onAddCheckBox,
      child: Opacity(
        opacity: isMaxReached ? 0.4 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.grey500,
              ),
              const SizedBox(width: 8),
              Text(
                isMaxReached ? '최대 $_maxCheckBoxes개' : '체크박스 추가',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final isMaxReached = _categories.length >= _maxCategories;

    return GestureDetector(
      onTap: isMaxReached ? null : _onAddCategory,
      child: Opacity(
        opacity: isMaxReached ? 0.4 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.grey500,
              ),
              const SizedBox(width: 8),
              Text(
                isMaxReached ? '최대 $_maxCategories개' : '카테고리 추가',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '완료',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnAccent,
          ),
        ),
      ),
    );
  }
}

/// 개별 카테고리 이모지/이름 수정 다이얼로그
class _CategoryItemEditDialog extends StatefulWidget {
  final Category? category;

  const _CategoryItemEditDialog({this.category});

  static Future<({String emoji, String name})?> show(
    BuildContext context, {
    Category? category,
  }) {
    return showDialog<({String emoji, String name})>(
      context: context,
      builder: (context) => _CategoryItemEditDialog(category: category),
    );
  }

  @override
  State<_CategoryItemEditDialog> createState() => _CategoryItemEditDialogState();
}

class _CategoryItemEditDialogState extends State<_CategoryItemEditDialog> {
  late TextEditingController _nameController;
  String _selectedEmoji = '';
  bool _showEmojiPicker = false;
  bool _emojiError = false;
  bool _nameError = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.category?.emoji ?? '';
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _nameController.addListener(() {
      if (_nameError && _nameController.text.trim().isNotEmpty) {
        setState(() => _nameError = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onEmojiSelected(emoji_picker.Category? category, emoji_picker.Emoji emoji) {
    setState(() {
      _selectedEmoji = emoji.emoji;
      _showEmojiPicker = false;
      _emojiError = false;
    });
  }

  void _onConfirm() {
    final name = _nameController.text.trim();

    setState(() {
      _emojiError = _selectedEmoji.isEmpty;
      _nameError = name.isEmpty;
    });

    if (_emojiError || _nameError) return;

    Navigator.pop(context, (emoji: _selectedEmoji, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? '카테고리 수정' : '새 카테고리',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // 이모지 선택 영역
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: _emojiError
                        ? Border.all(color: Colors.red, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: _selectedEmoji.isEmpty
                        ? Icon(
                            Icons.add_rounded,
                            size: 32,
                            color: _emojiError ? Colors.red : AppColors.grey400,
                          )
                        : Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                  ),
                ),
              ),
              // 이모지 피커
              if (_showEmojiPicker)
                Container(
                  height: 250,
                  margin: const EdgeInsets.only(top: 8),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: emoji_picker.EmojiPicker(
                    onEmojiSelected: _onEmojiSelected,
                    config: const emoji_picker.Config(
                      emojiViewConfig: emoji_picker.EmojiViewConfig(
                        columns: 7,
                      ),
                      categoryViewConfig: emoji_picker.CategoryViewConfig(
                        initCategory: emoji_picker.Category.SMILEYS,
                      ),
                      bottomActionBarConfig: emoji_picker.BottomActionBarConfig(
                        enabled: false,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            // 이름 입력
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              maxLength: 8,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '카테고리 이름',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey400,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _nameError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _nameError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 버튼
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _onConfirm,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 체크박스 이름 수정 다이얼로그
class _CheckBoxItemEditDialog extends StatefulWidget {
  final CheckBox? checkBox;

  const _CheckBoxItemEditDialog({this.checkBox});

  static Future<String?> show(
    BuildContext context, {
    CheckBox? checkBox,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _CheckBoxItemEditDialog(checkBox: checkBox),
    );
  }

  @override
  State<_CheckBoxItemEditDialog> createState() => _CheckBoxItemEditDialogState();
}

class _CheckBoxItemEditDialogState extends State<_CheckBoxItemEditDialog> {
  late TextEditingController _nameController;
  bool _nameError = false;

  bool get _isEditing => widget.checkBox != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.checkBox?.name ?? '');
    _nameController.addListener(() {
      if (_nameError && _nameController.text.trim().isNotEmpty) {
        setState(() => _nameError = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? '체크박스 수정' : '새 체크박스',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // 이름 입력
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 20,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '할 일 이름',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey400,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _nameError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _nameError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              onSubmitted: (_) => _onConfirm(),
            ),
            const SizedBox(height: 24),
            // 버튼
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _onConfirm,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
