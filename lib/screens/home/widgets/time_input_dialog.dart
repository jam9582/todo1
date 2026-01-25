import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/category.dart';

/// 시간 입력 다이얼로그
/// 시간/분 박스 선택 + 숫자 키패드 + 퀵버튼
class TimeInputDialog extends StatefulWidget {
  final Category category;
  final int initialMinutes;

  const TimeInputDialog({
    super.key,
    required this.category,
    this.initialMinutes = 0,
  });

  /// 다이얼로그를 표시하고 입력된 분(minutes)을 반환
  static Future<int?> show(
    BuildContext context, {
    required Category category,
    int initialMinutes = 0,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => TimeInputDialog(
        category: category,
        initialMinutes: initialMinutes,
      ),
    );
  }

  @override
  State<TimeInputDialog> createState() => _TimeInputDialogState();
}

enum _InputField { hours, minutes }

class _TimeEntry {
  int hours;
  int minutes;
  String operator; // '', '+', '-'

  _TimeEntry({this.hours = 0, this.minutes = 0, this.operator = ''});

  int get totalMinutes => hours * 60 + minutes;

  _TimeEntry copy() => _TimeEntry(hours: hours, minutes: minutes, operator: operator);
}

class _HistoryState {
  final List<_TimeEntry> entries;
  final int selectedEntryIndex;
  final _InputField selectedField;
  final String? activeOperator;

  _HistoryState({
    required this.entries,
    required this.selectedEntryIndex,
    required this.selectedField,
    required this.activeOperator,
  });
}

class _TimeInputDialogState extends State<TimeInputDialog> {
  final List<_TimeEntry> _entries = [];
  int _selectedEntryIndex = 0;
  _InputField _selectedField = _InputField.hours;
  String? _activeOperator;
  bool _isFirstInput = true;
  final List<_HistoryState> _history = [];

  @override
  void initState() {
    super.initState();
    final initialHours = widget.initialMinutes ~/ 60;
    final initialMins = widget.initialMinutes % 60;
    _entries.add(_TimeEntry(hours: initialHours, minutes: initialMins));
  }

  int get _totalMinutes {
    if (_entries.isEmpty) return 0;

    int total = _entries[0].totalMinutes;
    for (int i = 1; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.operator == '+') {
        total += entry.totalMinutes;
      } else if (entry.operator == '-') {
        total -= entry.totalMinutes;
      }
    }
    return total.clamp(0, 9999);
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    if (mins > 0) return '${mins}m';
    return '0m';
  }

  void _onNumberPressed(String number) {
    _saveHistory();
    setState(() {
      final entry = _entries[_selectedEntryIndex];
      if (_selectedField == _InputField.hours) {
        if (_isFirstInput) {
          entry.hours = int.parse(number);
          _isFirstInput = false;
        } else {
          final newValue = entry.hours * 10 + int.parse(number);
          if (newValue <= 99) {
            entry.hours = newValue;
          }
        }
      } else {
        if (_isFirstInput) {
          entry.minutes = int.parse(number);
          _isFirstInput = false;
        } else {
          final newValue = entry.minutes * 10 + int.parse(number);
          if (newValue <= 59) {
            entry.minutes = newValue;
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    _saveHistory();
    setState(() {
      final entry = _entries[_selectedEntryIndex];
      if (_selectedField == _InputField.hours) {
        entry.hours = entry.hours ~/ 10;
      } else {
        entry.minutes = entry.minutes ~/ 10;
      }
    });
  }

  void _saveHistory() {
    _history.add(_HistoryState(
      entries: _entries.map((e) => e.copy()).toList(),
      selectedEntryIndex: _selectedEntryIndex,
      selectedField: _selectedField,
      activeOperator: _activeOperator,
    ));
    if (_history.length > 50) {
      _history.removeAt(0);
    }
  }

  void _onUndoPressed() {
    if (_history.isEmpty) return;
    setState(() {
      final lastState = _history.removeLast();
      _entries.clear();
      _entries.addAll(lastState.entries);
      _selectedEntryIndex = lastState.selectedEntryIndex;
      _selectedField = lastState.selectedField;
      _activeOperator = lastState.activeOperator;
      _isFirstInput = true;
    });
  }

  void _onOperatorPressed(String op) {
    if (_entries.length >= 2) return;

    _saveHistory();
    setState(() {
      _entries.add(_TimeEntry(operator: op));
      _selectedEntryIndex = _entries.length - 1;
      _selectedField = _InputField.hours;
      _activeOperator = op;
      _isFirstInput = true;
    });
  }

  void _onQuickButtonPressed(int mins) {
    _saveHistory();
    setState(() {
      final entry = _entries[_selectedEntryIndex];
      final addHours = mins ~/ 60;
      final addMins = mins % 60;

      entry.minutes += addMins;
      if (entry.minutes >= 60) {
        entry.hours += entry.minutes ~/ 60;
        entry.minutes = entry.minutes % 60;
      }
      entry.hours += addHours;
      if (entry.hours > 99) entry.hours = 99;
    });
  }

  void _removeEntry(int index) {
    if (index == 0 || _entries.length <= 1) return;
    _saveHistory();
    setState(() {
      _entries.removeAt(index);
      if (_selectedEntryIndex >= _entries.length) {
        _selectedEntryIndex = _entries.length - 1;
      }
      if (_entries.length == 1) {
        _activeOperator = null;
      } else {
        _activeOperator = _entries.last.operator;
      }
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop(_totalMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTimeDisplay(),
            const SizedBox(height: 20),
            _buildQuickButtons(),
            const SizedBox(height: 20),
            _buildKeypad(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          widget.category.emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          widget.category.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Column(
      children: [
        // 시간 입력 영역
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _entries.length; i++) ...[
              if (i > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _entries[i].operator,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
              _buildTimeEntryBox(i),
            ],
            const SizedBox(width: 12),
            _buildOperatorButtons(),
          ],
        ),
        const SizedBox(height: 16),
        // 합계
        if (_entries.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '= ${_formatTime(_totalMinutes)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeEntryBox(int index) {
    final entry = _entries[index];
    final isSelected = _selectedEntryIndex == index;
    final canDelete = index > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.grey100 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFieldBox(index, _InputField.hours, entry.hours, 'h'),
              const SizedBox(width: 4),
              _buildFieldBox(index, _InputField.minutes, entry.minutes, 'm'),
            ],
          ),
        ),
        if (canDelete)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removeEntry(index),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.grey400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldBox(int entryIndex, _InputField field, int value, String unit) {
    final isSelected = _selectedEntryIndex == entryIndex && _selectedField == field;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEntryIndex = entryIndex;
          _selectedField = field;
          _isFirstInput = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.grey300 : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorButtons() {
    final isDisabled = _entries.length >= 2;

    return Column(
      children: [
        _buildOperatorButton('+', isDisabled),
        const SizedBox(height: 4),
        _buildOperatorButton('-', isDisabled),
      ],
    );
  }

  Widget _buildOperatorButton(String op, bool isDisabled) {
    final isActive = _activeOperator == op;

    return GestureDetector(
      onTap: isDisabled && !isActive ? null : () => _onOperatorPressed(op),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            op,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? AppColors.textOnPrimary
                  : (isDisabled ? AppColors.grey400 : AppColors.grey600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButtons() {
    final quickValues = [
      (15, '+15m'),
      (30, '+30m'),
      (60, '+1h'),
      (120, '+2h'),
    ];

    return Row(
      children: quickValues.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _onQuickButtonPressed(item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildKeypadRow(['undo', '0', 'backspace']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildKeypadButton(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final isNumber = int.tryParse(key) != null;
    final isDelete = key == 'backspace';
    final isUndo = key == 'undo';

    return GestureDetector(
      onTap: () {
        if (isNumber) {
          _onNumberPressed(key);
        } else if (isDelete) {
          _onDeletePressed();
        } else if (isUndo) {
          _onUndoPressed();
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isNumber ? AppColors.grey100 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isNumber
              ? Text(
                  key,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                )
              : Icon(
                  isUndo ? Icons.undo_rounded : Icons.backspace_outlined,
                  size: 24,
                  color: AppColors.grey500,
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              backgroundColor: AppColors.textPrimary,
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
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
