// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get delete => '삭제';

  @override
  String get done => '완료';

  @override
  String get settingsTitle => '설정';

  @override
  String get sectionCalendar => '달력 설정';

  @override
  String get labelWeekStart => '주 시작 요일';

  @override
  String get sunday => '일요일';

  @override
  String get monday => '월요일';

  @override
  String get sectionCalendarDisplay => '달력 표시 설정';

  @override
  String get labelCategoryDisplay => '카테고리 표시 방식';

  @override
  String get displayModeTopCategory => '최다 활동';

  @override
  String get displayModeFixedCategory => '특정 카테고리';

  @override
  String get labelDisplayCategory => '표시할 카테고리';

  @override
  String get dropdownHint => '선택';

  @override
  String get labelShowActivityTime => '카테고리 활동시간 표시';

  @override
  String get labelShowCheckCount => '체크박스 완료 개수 표시';

  @override
  String get sectionNotification => '알림';

  @override
  String get labelDailyNotif => '매일 알림';

  @override
  String get labelNotifTime => '알림 시간';

  @override
  String get sectionPurchase => '구매';

  @override
  String get labelRestorePurchase => '구매 복원';

  @override
  String get labelPurchaseHistory => '구매 내역 및 지원';

  @override
  String get sectionAppInfo => '앱 정보';

  @override
  String get labelVersion => '버전';

  @override
  String get msgPurchaseRestored => '구매 내역을 복원했습니다!';

  @override
  String get msgNoPurchaseToRestore => '복원할 구매 내역이 없습니다';

  @override
  String get msgRestoreFailed => '복원에 실패했습니다. 다시 시도해주세요.';

  @override
  String get menuStatistics => '통계';

  @override
  String get menuCategoryEdit => '카테고리 편집';

  @override
  String get menuRemoveAds => '광고 제거';

  @override
  String get msgAdsAlreadyRemoved => '이미 광고가 제거된 상태입니다 ✓';

  @override
  String get msgAdsRemoved => '광고가 제거되었습니다!';

  @override
  String get periodWeekly => '주간';

  @override
  String get periodMonthly => '월간';

  @override
  String get noData => '데이터가 없습니다';

  @override
  String get chartWeeklyTrend => '주간 활동 추이';

  @override
  String get chartMonthlyTrend => '월간 활동 추이';

  @override
  String get chartWeeklyTotal => '주간 카테고리별 총합';

  @override
  String get chartMonthlyTotal => '월간 카테고리별 총합';

  @override
  String get dailyMessageLabel => '오늘의 한마디';

  @override
  String get dailyMessagePlaceholder => '언제나 당신을 응원해요';

  @override
  String get emptyCategoryMessage => '카테고리를 만들어보세요!';

  @override
  String get tabCategory => '카테고리';

  @override
  String get tabCheckbox => '체크박스';

  @override
  String get dialogDeleteCategoryTitle => '카테고리 삭제';

  @override
  String dialogDeleteCategoryContent(String name) {
    return '\'$name\' 카테고리를 삭제하시겠습니까?';
  }

  @override
  String get dialogDeleteCheckboxTitle => '체크박스 삭제';

  @override
  String dialogDeleteCheckboxContent(String name) {
    return '\'$name\' 항목을 삭제하시겠습니까?';
  }

  @override
  String get emptyCheckboxMessage => '체크박스를 추가해보세요';

  @override
  String addItemMax(int count) {
    return '최대 $count개';
  }

  @override
  String get checkboxAdd => '체크박스 추가';

  @override
  String get categoryAdd => '카테고리 추가';

  @override
  String get dialogEditCategoryTitle => '카테고리 수정';

  @override
  String get dialogNewCategoryTitle => '새 카테고리';

  @override
  String get hintCategoryName => '카테고리 이름';

  @override
  String get dialogEditCheckboxTitle => '체크박스 수정';

  @override
  String get dialogNewCheckboxTitle => '새 체크박스';

  @override
  String get hintTaskName => '할 일 이름';

  @override
  String get sectionLanguage => '언어';

  @override
  String get labelLanguage => '언어';

  @override
  String get langSystem => '시스템';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get notifChannelName => '매일 알림';

  @override
  String get notifTitle => '오늘 하루는 어땠나요?';

  @override
  String get notifBody => '오늘의 활동을 기록해보세요.';
}
