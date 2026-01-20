/// 앱 전체에서 사용하는 시간 관련 상수
class AppDurations {
  AppDurations._();

  // Throttle (중복 터치 방지)
  static const Duration throttle = Duration(milliseconds: 300);

  // SnackBar
  static const Duration snackBar = Duration(seconds: 1);

  // 애니메이션 (나중에 필요시 사용)
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
