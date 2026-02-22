import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'providers/category_provider.dart';
import 'providers/check_box_provider.dart';
import 'providers/record_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/home/home_screen.dart';
import 'constants/app_theme.dart';
import 'constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 & 네비게이션바 스타일 설정 (Android)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // 상태바 (상단)
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      // 네비게이션바 (하단)
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Isar 초기화
  await IsarService.instance;

  // 알림 초기화
  await NotificationService.initialize();

  // RevenueCat 초기화
  await PurchaseProvider.configure();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => CheckBoxProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: const _AppWithLocale(),
    );
  }
}

class _AppWithLocale extends StatelessWidget {
  const _AppWithLocale();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;

    Locale? locale;
    if (lang == 'ko') {
      locale = const Locale('ko');
    } else if (lang == 'en') {
      locale = const Locale('en');
    }
    // lang == 'system' → locale = null, localeResolutionCallback 로 결정

    return MaterialApp(
      title: 'Todo1 App',
      theme: AppTheme.theme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      // 시스템 언어가 ko/en 아닌 경우 English로 fallback
      localeResolutionCallback: locale != null
          ? null
          : (deviceLocale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (deviceLocale?.languageCode == supported.languageCode) {
                  return supported;
                }
              }
              return const Locale('en');
            },
      home: const HomeScreen(),
    );
  }
}
