import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../theme/app_theme.dart';

/// 시간 입력 다이얼로그
/// 숫자 키패드 + 퀵버튼 + 계산기 기능으로 분 단위 입력
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

class _TimeInputDialogState extends State<TimeInputDialog> {
  String _expression = '';
  String? _pendingOperator;
  int _accumulator = 0;
  bool _startNewNumber = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialMinutes > 0) {
      _expression = widget.initialMinutes.toString();
      _accumulator = widget.initialMinutes;
      _startNewNumber = true;
    }
  }

  int get _currentResult {
    if (_pendingOperator != null && _expression.isNotEmpty) {
      final currentNum = _parseLastNumber();
      return _calculate(_accumulator, _pendingOperator!, currentNum);
    }
    return _parseLastNumber();
  }

  int _parseLastNumber() {
    if (_expression.isEmpty) return 0;

    // 마지막 연산자 이후의 숫자를 파싱
    final lastPlusIndex = _expression.lastIndexOf('+');
    final lastMinusIndex = _expression.lastIndexOf('-');
    final lastOperatorIndex = lastPlusIndex > lastMinusIndex ? lastPlusIndex : lastMinusIndex;

    if (lastOperatorIndex == -1) {
      return int.tryParse(_expression) ?? 0;
    }

    final lastNumberStr = _expression.substring(lastOperatorIndex + 1).trim();
    return int.tryParse(lastNumberStr) ?? 0;
  }

  int _calculate(int a, String op, int b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return (a - b).clamp(0, 9999);
      default:
        return b;
    }
  }

  String _formatTime(int minutes) {
    if (minutes == 0) return '0분';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '$hours시간 $mins분';
    if (hours > 0) return '$hours시간';
    return '$mins분';
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_startNewNumber && _pendingOperator == null) {
        _expression = number;
        _startNewNumber = false;
      } else {
        // 현재 입력 중인 숫자가 4자리 미만일 때만 추가
        final lastNum = _parseLastNumber().toString();
        if (lastNum.length < 4 || _startNewNumber) {
          if (_startNewNumber && _pendingOperator != null) {
            _expression += number;
            _startNewNumber = false;
          } else {
            _expression += number;
          }
        }
      }
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      if (_expression.isEmpty) return;

      // 이전 연산 완료
      if (_pendingOperator != null && !_startNewNumber) {
        final currentNum = _parseLastNumber();
        _accumulator = _calculate(_accumulator, _pendingOperator!, currentNum);
        _expression = '$_accumulator $op ';
      } else {
        _accumulator = _parseLastNumber();
        _expression = '$_accumulator $op ';
      }

      _pendingOperator = op;
      _startNewNumber = true;
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_expression.isNotEmpty) {
        // 마지막 문자가 공백이면 연산자까지 삭제
        if (_expression.endsWith(' ')) {
          _expression = _expression.trimRight();
          if (_expression.endsWith('+') || _expression.endsWith('-')) {
            _expression = _expression.substring(0, _expression.length - 1).trimRight();
            _pendingOperator = null;
            _accumulator = int.tryParse(_expression) ?? 0;
          }
        } else {
          _expression = _expression.substring(0, _expression.length - 1);
        }

        if (_expression.isEmpty) {
          _pendingOperator = null;
          _accumulator = 0;
          _startNewNumber = true;
        }
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _expression = '';
      _pendingOperator = null;
      _accumulator = 0;
      _startNewNumber = true;
    });
  }

  void _onQuickButtonPressed(int minutes) {
    setState(() {
      // 기존 연산이 진행 중이면 먼저 계산 완료
      if (_pendingOperator != null && !_startNewNumber) {
        final currentNum = _parseLastNumber();
        _accumulator = _calculate(_accumulator, _pendingOperator!, currentNum);
      } else if (_expression.isNotEmpty) {
        _accumulator = _currentResult;
      }

      // 수식에 + minutes 추가
      _expression = '$_accumulator + $minutes';
      _pendingOperator = '+';
      _startNewNumber = false;
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop(_currentResult);
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
    final hasOperator = _pendingOperator != null && !_startNewNumber;
    final result = _currentResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          // 수식 표시
          Text(
            _expression.isEmpty ? '0' : _expression,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 계산 결과 (연산자가 있을 때만)
          if (hasOperator) ...[
            const SizedBox(height: 4),
            Text(
              '= $result',
              style: TextStyle(
                fontSize: AppTheme.fontSizeH3,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatTime(result),
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    final quickValues = [
      (15, '+15분'),
      (30, '+30분'),
      (60, '+1시간'),
      (120, '+2시간'),
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
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: Text(
                item.$2,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeCaption,
                  color: AppTheme.primaryColor,
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
        _buildKeypadRow(['C', '0', '⌫']),
        const SizedBox(height: 8),
        _buildKeypadRow(['-', '', '+']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: key.isEmpty
              ? const SizedBox()
              : _buildKeypadButton(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final isNumber = int.tryParse(key) != null;
    final isDelete = key == '⌫';
    final isClear = key == 'C';
    final isOperator = key == '+' || key == '-';

    Color bgColor;
    if (isOperator) {
      bgColor = AppTheme.primaryColor.withValues(alpha: 0.15);
    } else if (isNumber) {
      bgColor = Colors.grey.shade200;
    } else {
      bgColor = Colors.grey.shade300;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () {
          if (isNumber) {
            _onNumberPressed(key);
          } else if (isDelete) {
            _onDeletePressed();
          } else if (isClear) {
            _onClearPressed();
          } else if (isOperator) {
            _onOperatorPressed(key);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            key,
            style: TextStyle(
              fontSize: isOperator ? 24 : (isNumber ? 20 : 18),
              fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
              color: isOperator ? AppTheme.primaryColor : Colors.black87,
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
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
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
