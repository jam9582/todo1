import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/category.dart';
import '../../../theme/app_theme.dart';

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
  String? _activeOperator; // 현재 활성화된 연산자
  bool _isFirstInput = true; // 필드 선택 후 첫 입력인지
  final List<_HistoryState> _history = []; // Undo 히스토리

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

  String _formatTimeHM(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  void _onNumberPressed(String number) {
    _saveHistory();
    setState(() {
      final entry = _entries[_selectedEntryIndex];
      if (_selectedField == _InputField.hours) {
        if (_isFirstInput) {
          // 첫 입력이면 기존 값 지우고 새로 시작
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
    // 히스토리는 최대 50개까지만 유지
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
    // 이미 두 번째 엔트리가 있으면 추가 불가 (연산은 한 번만)
    if (_entries.length >= 2) return;

    _saveHistory();
    setState(() {
      _entries.add(_TimeEntry(operator: op));
      _selectedEntryIndex = _entries.length - 1;
      _selectedField = _InputField.hours;
      _activeOperator = op;
      _isFirstInput = true; // 새 엔트리는 첫 입력 상태
    });
  }

  void _onQuickButtonPressed(int mins) {
    _saveHistory();
    setState(() {
      // 현재 선택된 엔트리에 시간 추가
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
      // 연산자 활성화 상태 업데이트
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTimeDisplay(),
            const SizedBox(height: 16),
            _buildQuickButtons(),
            const SizedBox(height: 16),
            _buildKeypad(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.category.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: 8),
        Text(
          widget.category.name,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeH3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          // 시간 입력 영역 - 가운데 정렬
          Row(
            children: [
              // 시간 엔트리들 - 가운데 정렬
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (int i = 0; i < _entries.length; i++)
                        _buildTimeEntryBox(i),
                    ],
                  ),
                ),
              ),
              // +/- 버튼
              Column(
                children: [
                  _buildOperatorButton('+'),
                  const SizedBox(height: 4),
                  _buildOperatorButton('-'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 합계 표시 - 강조
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '= ${_formatTimeHM(_totalMinutes)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
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
        // 삭제 버튼 (첫 번째 엔트리 제외)
        if (canDelete)
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => _removeEntry(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.grey500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
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
          _isFirstInput = true; // 필드 선택 시 첫 입력 상태로
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$value$unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorButton(String op) {
    final isActive = _activeOperator == op;
    final isDisabled = _entries.length >= 2; // 이미 연산 중이면 비활성화

    return Opacity(
      opacity: isDisabled && !isActive ? 0.4 : 1.0,
      child: Material(
        color: isActive ? AppColors.primary : AppColors.grey300,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isDisabled ? null : () => _onOperatorPressed(op),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              op,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.textOnPrimary : AppColors.grey600,
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => _onQuickButtonPressed(item.$1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: Text(
                item.$2,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeCaption,
                  color: AppColors.primary,
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
        const SizedBox(height: 8),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildKeypadRow(['undo', '0', 'backspace']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadButton(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final isNumber = int.tryParse(key) != null;
    final isDelete = key == 'backspace';
    final isUndo = key == 'undo';
    final isIcon = isDelete || isUndo;

    Color bgColor = isNumber ? AppColors.grey200 : AppColors.grey300;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () {
          if (isNumber) {
            _onNumberPressed(key);
          } else if (isDelete) {
            _onDeletePressed();
          } else if (isUndo) {
            _onUndoPressed();
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: isIcon
              ? Icon(
                  isUndo ? Icons.undo : Icons.backspace_outlined,
                  size: 22,
                  color: AppColors.grey700,
                )
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: isNumber ? 20 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            child: const Text('취소'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            child: const Text('확인'),
          ),
        ),
      ],
    );
  }
}
