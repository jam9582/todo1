import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @sectionCalendar.
  ///
  /// In ko, this message translates to:
  /// **'달력 설정'**
  String get sectionCalendar;

  /// No description provided for @labelWeekStart.
  ///
  /// In ko, this message translates to:
  /// **'주 시작 요일'**
  String get labelWeekStart;

  /// No description provided for @sunday.
  ///
  /// In ko, this message translates to:
  /// **'일요일'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In ko, this message translates to:
  /// **'월요일'**
  String get monday;

  /// No description provided for @sectionCalendarDisplay.
  ///
  /// In ko, this message translates to:
  /// **'달력 표시 설정'**
  String get sectionCalendarDisplay;

  /// No description provided for @labelCategoryDisplay.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 표시 방식'**
  String get labelCategoryDisplay;

  /// No description provided for @displayModeTopCategory.
  ///
  /// In ko, this message translates to:
  /// **'최다 활동'**
  String get displayModeTopCategory;

  /// No description provided for @displayModeFixedCategory.
  ///
  /// In ko, this message translates to:
  /// **'특정 카테고리'**
  String get displayModeFixedCategory;

  /// No description provided for @labelDisplayCategory.
  ///
  /// In ko, this message translates to:
  /// **'표시할 카테고리'**
  String get labelDisplayCategory;

  /// No description provided for @dropdownHint.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get dropdownHint;

  /// No description provided for @labelShowActivityTime.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 활동시간 표시'**
  String get labelShowActivityTime;

  /// No description provided for @labelShowCheckCount.
  ///
  /// In ko, this message translates to:
  /// **'체크박스 완료 개수 표시'**
  String get labelShowCheckCount;

  /// No description provided for @sectionNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get sectionNotification;

  /// No description provided for @labelDailyNotif.
  ///
  /// In ko, this message translates to:
  /// **'매일 알림'**
  String get labelDailyNotif;

  /// No description provided for @labelNotifTime.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get labelNotifTime;

  /// No description provided for @sectionPurchase.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get sectionPurchase;

  /// No description provided for @labelRestorePurchase.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get labelRestorePurchase;

  /// No description provided for @labelPurchaseHistory.
  ///
  /// In ko, this message translates to:
  /// **'구매 내역 및 지원'**
  String get labelPurchaseHistory;

  /// No description provided for @sectionAppInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get sectionAppInfo;

  /// No description provided for @labelVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get labelVersion;

  /// No description provided for @msgPurchaseRestored.
  ///
  /// In ko, this message translates to:
  /// **'구매 내역을 복원했습니다!'**
  String get msgPurchaseRestored;

  /// No description provided for @msgNoPurchaseToRestore.
  ///
  /// In ko, this message translates to:
  /// **'복원할 구매 내역이 없습니다'**
  String get msgNoPurchaseToRestore;

  /// No description provided for @msgRestoreFailed.
  ///
  /// In ko, this message translates to:
  /// **'복원에 실패했습니다. 다시 시도해주세요.'**
  String get msgRestoreFailed;

  /// No description provided for @menuStatistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get menuStatistics;

  /// No description provided for @menuCategoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 편집'**
  String get menuCategoryEdit;

  /// No description provided for @menuRemoveAds.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거'**
  String get menuRemoveAds;

  /// No description provided for @msgAdsAlreadyRemoved.
  ///
  /// In ko, this message translates to:
  /// **'이미 광고가 제거된 상태입니다 ✓'**
  String get msgAdsAlreadyRemoved;

  /// No description provided for @msgAdsRemoved.
  ///
  /// In ko, this message translates to:
  /// **'광고가 제거되었습니다!'**
  String get msgAdsRemoved;

  /// No description provided for @periodWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get periodMonthly;

  /// No description provided for @noData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get noData;

  /// No description provided for @chartWeeklyTrend.
  ///
  /// In ko, this message translates to:
  /// **'주간 활동 추이'**
  String get chartWeeklyTrend;

  /// No description provided for @chartMonthlyTrend.
  ///
  /// In ko, this message translates to:
  /// **'월간 활동 추이'**
  String get chartMonthlyTrend;

  /// No description provided for @chartWeeklyTotal.
  ///
  /// In ko, this message translates to:
  /// **'주간 카테고리별 총합'**
  String get chartWeeklyTotal;

  /// No description provided for @chartMonthlyTotal.
  ///
  /// In ko, this message translates to:
  /// **'월간 카테고리별 총합'**
  String get chartMonthlyTotal;

  /// No description provided for @dailyMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 한마디'**
  String get dailyMessageLabel;

  /// No description provided for @dailyMessagePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'언제나 당신을 응원해요'**
  String get dailyMessagePlaceholder;

  /// No description provided for @emptyCategoryMessage.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 만들어보세요!'**
  String get emptyCategoryMessage;

  /// No description provided for @tabCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get tabCategory;

  /// No description provided for @tabCheckbox.
  ///
  /// In ko, this message translates to:
  /// **'체크박스'**
  String get tabCheckbox;

  /// No description provided for @dialogDeleteCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 삭제'**
  String get dialogDeleteCategoryTitle;

  /// No description provided for @dialogDeleteCategoryContent.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 카테고리를 삭제하시겠습니까?'**
  String dialogDeleteCategoryContent(String name);

  /// No description provided for @dialogDeleteCheckboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'체크박스 삭제'**
  String get dialogDeleteCheckboxTitle;

  /// No description provided for @dialogDeleteCheckboxContent.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 항목을 삭제하시겠습니까?'**
  String dialogDeleteCheckboxContent(String name);

  /// No description provided for @emptyCheckboxMessage.
  ///
  /// In ko, this message translates to:
  /// **'체크박스를 추가해보세요'**
  String get emptyCheckboxMessage;

  /// No description provided for @addItemMax.
  ///
  /// In ko, this message translates to:
  /// **'최대 {count}개'**
  String addItemMax(int count);

  /// No description provided for @checkboxAdd.
  ///
  /// In ko, this message translates to:
  /// **'체크박스 추가'**
  String get checkboxAdd;

  /// No description provided for @categoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 추가'**
  String get categoryAdd;

  /// No description provided for @dialogEditCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 수정'**
  String get dialogEditCategoryTitle;

  /// No description provided for @dialogNewCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 카테고리'**
  String get dialogNewCategoryTitle;

  /// No description provided for @hintCategoryName.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름'**
  String get hintCategoryName;

  /// No description provided for @dialogEditCheckboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'체크박스 수정'**
  String get dialogEditCheckboxTitle;

  /// No description provided for @dialogNewCheckboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 체크박스'**
  String get dialogNewCheckboxTitle;

  /// No description provided for @hintTaskName.
  ///
  /// In ko, this message translates to:
  /// **'할 일 이름'**
  String get hintTaskName;

  /// No description provided for @sectionLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get sectionLanguage;

  /// No description provided for @labelLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get labelLanguage;

  /// No description provided for @langSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get langSystem;

  /// No description provided for @langKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get langKorean;

  /// No description provided for @langEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @notifChannelName.
  ///
  /// In ko, this message translates to:
  /// **'매일 알림'**
  String get notifChannelName;

  /// No description provided for @notifTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루는 어땠나요?'**
  String get notifTitle;

  /// No description provided for @notifBody.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 활동을 기록해보세요.'**
  String get notifBody;

  /// No description provided for @restDay.
  ///
  /// In ko, this message translates to:
  /// **'쉬는 날'**
  String get restDay;

  /// No description provided for @restDayFill.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 쉬려구요'**
  String get restDayFill;

  /// No description provided for @restDayOverlay.
  ///
  /// In ko, this message translates to:
  /// **'잘 쉬고 오세요 :)'**
  String get restDayOverlay;

  /// No description provided for @timerTitle.
  ///
  /// In ko, this message translates to:
  /// **'타이머'**
  String get timerTitle;

  /// No description provided for @timerStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get timerStart;

  /// No description provided for @timerPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get timerPause;

  /// No description provided for @timerResume.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get timerResume;

  /// No description provided for @timerComplete.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get timerComplete;

  /// No description provided for @timerSelectCategory.
  ///
  /// In ko, this message translates to:
  /// **'어느 카테고리에 추가할까요?'**
  String get timerSelectCategory;

  /// No description provided for @timerAdded.
  ///
  /// In ko, this message translates to:
  /// **'기록에 추가됐어요'**
  String get timerAdded;

  /// No description provided for @timerTooShort.
  ///
  /// In ko, this message translates to:
  /// **'1분 미만 활동은 기록되지 않아요'**
  String get timerTooShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
