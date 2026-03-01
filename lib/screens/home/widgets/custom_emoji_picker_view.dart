import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class CustomEmojiPickerView extends StatefulWidget {
  final Config config;
  final EmojiViewState state;

  const CustomEmojiPickerView({
    super.key,
    required this.config,
    required this.state,
  });

  @override
  State<CustomEmojiPickerView> createState() => _CustomEmojiPickerViewState();
}

class _CustomEmojiPickerViewState extends State<CustomEmojiPickerView> {
  late PageController _pageController;
  late int _currentIndex;

  static const _categoryIcons = <Category, IconData>{
    Category.RECENT: Icons.access_time,
    Category.SMILEYS: Icons.tag_faces,
    Category.ANIMALS: Icons.pets,
    Category.FOODS: Icons.fastfood,
    Category.ACTIVITIES: Icons.directions_run,
    Category.TRAVEL: Icons.location_city,
    Category.OBJECTS: Icons.lightbulb_outline,
    Category.SYMBOLS: Icons.emoji_symbols,
    Category.FLAGS: Icons.flag,
  };

  @override
  void initState() {
    super.initState();
    final initCategory = widget.state.currentCategory ??
        widget.config.categoryViewConfig.initCategory;
    _currentIndex = widget.state.categoryEmoji
        .indexWhere((e) => e.category == initCategory);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    _pageController.jumpToPage(index);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.categoryEmoji;

    return Column(
      children: [
        _buildCategoryBar(categories),
        const Divider(height: 1, color: AppColors.borderLight),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: categories.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.state.onCategoryChanged?.call(categories[index].category);
            },
            itemBuilder: (context, index) {
              return _EmojiGrid(
                key: ValueKey(categories[index].category),
                emojis: categories[index].emoji,
                category: categories[index].category,
                onEmojiSelected: widget.state.onEmojiSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar(List<CategoryEmoji> categories) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: List.generate(categories.length, (index) {
          final category = categories[index].category;
          final isSelected = index == _currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onCategoryTap(index),
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _categoryIcons[category] ?? Icons.emoji_emotions,
                    size: 18,
                    color: isSelected ? AppColors.textOnAccent : AppColors.grey400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 이모지 그리드 — 최소 위젯 트리로 성능 최적화
class _EmojiGrid extends StatelessWidget {
  final List<Emoji> emojis;
  final Category category;
  final OnEmojiSelected onEmojiSelected;

  const _EmojiGrid({
    super.key,
    required this.emojis,
    required this.category,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) {
      return const Center(
        child: Text(
          'No recent emojis',
          style: TextStyle(fontSize: 14, color: AppColors.grey400),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () => onEmojiSelected(category, emoji),
          child: Center(
            child: Text(
              emoji.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        );
      },
    );
  }
}
