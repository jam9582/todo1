import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/colors.dart';
import '../../../models/category.dart';
import '../../../l10n/app_localizations.dart';

/// 시간 입력 다이얼로그
class TimeInputDialog extends StatefulWidget {
  final Category category;
  final int initialMinutes;

  const TimeInputDialog({
    super.key,
    required this.category,
    this.initialMinutes = 0,
  });

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

class _HistoryState {
  final int hours;
  final int minutes;
  final _InputField selectedField;

  _HistoryState({
    required this.hours,
    required this.minutes,
    required this.selectedField,
  });
}

class _TimeInputDialogState extends State<TimeInputDialog> {
  static const int _maxMinutes = 1440; // 24시간 상한

  int _hours = 0;
  int _minutes = 0;
  _InputField _selectedField = _InputField.hours;
  bool _isFirstInput = true;
  final List<_HistoryState> _history = [];

  @override
  void initState() {
    super.initState();
    _hours = widget.initialMinutes ~/ 60;
    _minutes = widget.initialMinutes % 60;
  }

  int get _totalMinutes => _hours * 60 + _minutes;

  void _clampToMax() {
    if (_totalMinutes > _maxMinutes) {
      _hours = 24;
      _minutes = 0;
    }
  }

  void _saveHistory() {
    _history.add(_HistoryState(
      hours: _hours,
      minutes: _minutes,
      selectedField: _selectedField,
    ));
    if (_history.length > 50) {
      _history.removeAt(0);
    }
  }

  void _onNumberPressed(String number) {
    final digit = int.tryParse(number);
    if (digit == null) return;
    _saveHistory();
    setState(() {
      if (_selectedField == _InputField.hours) {
        if (_isFirstInput) {
          _hours = digit;
          _isFirstInput = false;
        } else {
          final newValue = _hours * 10 + digit;
          _hours = newValue.clamp(0, 24);
        }
      } else {
        if (_isFirstInput) {
          _minutes = digit;
          _isFirstInput = false;
        } else {
          final newValue = _minutes * 10 + digit;
          _minutes = newValue.clamp(0, 59);
        }
      }
      _clampToMax();
    });
  }

  void _onDeletePressed() {
    _saveHistory();
    setState(() {
      if (_selectedField == _InputField.hours) {
        _hours = _hours ~/ 10;
      } else {
        _minutes = _minutes ~/ 10;
      }
    });
  }

  void _onUndoPressed() {
    if (_history.isEmpty) return;
    setState(() {
      final lastState = _history.removeLast();
      _hours = lastState.hours;
      _minutes = lastState.minutes;
      _selectedField = lastState.selectedField;
      _isFirstInput = true;
    });
  }

  void _onQuickButtonPressed(int mins) {
    _saveHistory();
    setState(() {
      _minutes += mins % 60;
      if (_minutes >= 60) {
        _hours += _minutes ~/ 60;
        _minutes = _minutes % 60;
      }
      _hours += mins ~/ 60;
      _clampToMax();
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
            const SizedBox(height: 28),
            _buildTimeDisplay(),
            const SizedBox(height: 24),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFieldBox(_InputField.hours, _hours, 'h'),
        const SizedBox(width: 8),
        _buildFieldBox(_InputField.minutes, _minutes, 'm'),
      ],
    );
  }

  Widget _buildFieldBox(_InputField field, int value, String unit) {
    final isSelected = _selectedField == field;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedField = field;
          _isFirstInput = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.textOnAccent : AppColors.grey500,
              ),
            ),
          ],
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
              onTap: () {
                HapticFeedback.lightImpact();
                _onQuickButtonPressed(item.$1);
              },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonSize = (constraints.maxWidth / 4).clamp(48.0, 64.0);
        return Column(
          children: [
            _buildKeypadRow(['1', '2', '3'], buttonSize),
            const SizedBox(height: 12),
            _buildKeypadRow(['4', '5', '6'], buttonSize),
            const SizedBox(height: 12),
            _buildKeypadRow(['7', '8', '9'], buttonSize),
            const SizedBox(height: 12),
            _buildKeypadRow(['undo', '0', 'backspace'], buttonSize),
          ],
        );
      },
    );
  }

  Widget _buildKeypadRow(List<String> keys, double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return _buildKeypadButton(key, buttonSize);
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key, double buttonSize) {
    final isNumber = int.tryParse(key) != null;
    final isDelete = key == 'backspace';
    final isUndo = key == 'undo';
    final iconSize = buttonSize * 0.375;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isNumber) {
          _onNumberPressed(key);
        } else if (isDelete) {
          _onDeletePressed();
        } else if (isUndo) {
          _onUndoPressed();
        }
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isNumber ? AppColors.grey100 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isNumber
              ? Text(
                  key,
                  style: TextStyle(
                    fontSize: iconSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                )
              : Icon(
                  isUndo ? Icons.undo_rounded : Icons.backspace_outlined,
                  size: iconSize,
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
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(
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
            child: Text(
              AppLocalizations.of(context)!.confirm,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
