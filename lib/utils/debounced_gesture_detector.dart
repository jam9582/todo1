import 'dart:async';
import 'package:flutter/material.dart';

/// 중복 터치 방지 기능이 포함된 GestureDetector 래퍼
/// - 단순 터치: Throttle 방식 (기본 300ms)
/// - 비동기 작업: 작업 완료까지 추가 터치 차단
class DebouncedGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Future<void> Function()? onTapAsync;
  final Duration throttleDuration;
  final HitTestBehavior? behavior;

  const DebouncedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onTapAsync,
    this.throttleDuration = const Duration(milliseconds: 300),
    this.behavior,
  }) : assert(onTap != null || onTapAsync != null,
            'onTap 또는 onTapAsync 중 하나는 필수입니다');

  @override
  State<DebouncedGestureDetector> createState() =>
      _DebouncedGestureDetectorState();
}

class _DebouncedGestureDetectorState extends State<DebouncedGestureDetector> {
  bool _isProcessing = false;
  DateTime? _lastTapTime;

  Future<void> _handleTap() async {
    // 이미 처리 중이면 무시
    if (_isProcessing) return;

    // Throttle 체크: 마지막 터치로부터 일정 시간이 지나지 않았으면 무시
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < widget.throttleDuration) {
      return;
    }

    _lastTapTime = now;

    // 비동기 작업인 경우
    if (widget.onTapAsync != null) {
      setState(() => _isProcessing = true);
      try {
        await widget.onTapAsync!();
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
    // 동기 작업인 경우
    else if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}

/// 중복 터치 방지 기능이 포함된 IconButton 래퍼
class DebouncedIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final Duration throttleDuration;
  final double? iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Color? color;
  final String? tooltip;

  const DebouncedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onPressedAsync,
    this.throttleDuration = const Duration(milliseconds: 300),
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.color,
    this.tooltip,
  }) : assert(onPressed != null || onPressedAsync != null,
            'onPressed 또는 onPressedAsync 중 하나는 필수입니다');

  @override
  State<DebouncedIconButton> createState() => _DebouncedIconButtonState();
}

class _DebouncedIconButtonState extends State<DebouncedIconButton> {
  bool _isProcessing = false;
  DateTime? _lastTapTime;

  Future<void> _handleTap() async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < widget.throttleDuration) {
      return;
    }

    _lastTapTime = now;

    if (widget.onPressedAsync != null) {
      setState(() => _isProcessing = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } else if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: widget.icon,
      onPressed: _handleTap,
      iconSize: widget.iconSize,
      visualDensity: widget.visualDensity,
      padding: widget.padding,
      alignment: widget.alignment ?? Alignment.center,
      color: widget.color,
      tooltip: widget.tooltip,
    );
  }
}
