import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../theme/app_theme.dart';

/// 시간 입력 다이얼로그
/// 숫자 키패드 + 퀵버튼으로 분 단위 입력
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
  late String _inputValue;

  @override
  void initState() {
    super.initState();
    _inputValue = widget.initialMinutes > 0 ? widget.initialMinutes.toString() : '';
  }

  int get _currentMinutes => int.tryParse(_inputValue) ?? 0;

  String get _displayTime {
    final minutes = _currentMinutes;
    if (minutes == 0 && _inputValue.isEmpty) return '0분';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '$hours시간 $mins분';
    if (hours > 0) return '$hours시간';
    return '$mins분';
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_inputValue.length < 4) {
        _inputValue += number;
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_inputValue.isNotEmpty) {
        _inputValue = _inputValue.substring(0, _inputValue.length - 1);
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _inputValue = '';
    });
  }

  void _onQuickButtonPressed(int minutes) {
    setState(() {
      _inputValue = (_currentMinutes + minutes).toString();
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop(_currentMinutes);
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
            // 헤더: 카테고리 이모지 + 이름
            _buildHeader(),
            const SizedBox(height: 16),

            // 시간 디스플레이
            _buildTimeDisplay(),
            const SizedBox(height: 16),

            // 퀵버튼
            _buildQuickButtons(),
            const SizedBox(height: 16),

            // 숫자 키패드
            _buildKeypad(),
            const SizedBox(height: 16),

            // 확인/취소 버튼
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          Text(
            _inputValue.isEmpty ? '0' : _inputValue,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayTime,
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
    final isDelete = key == '⌫';
    final isClear = key == 'C';

    return Material(
      color: isNumber ? Colors.grey.shade200 : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () {
          if (isNumber) {
            _onNumberPressed(key);
          } else if (isDelete) {
            _onDeletePressed();
          } else if (isClear) {
            _onClearPressed();
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
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
