// 분을 시간 문자열로 변환하는 확장 메서드
extension MinutesToTime on int {
  String toTimeString() {
    if (this == 0) return '-';

    final hours = this ~/ 60;
    final minutes = this % 60;

    if (hours == 0) return '${minutes}분';
    if (minutes == 0) return '${hours}시간';

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}
