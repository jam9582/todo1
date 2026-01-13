import 'package:flutter/material.dart';

class AppTheme {
  // 색상
  static const primaryColor = Color(0xFFFF9966);
  static const backgroundColor = Colors.white;
  static const adBannerColor = Color(0xFFE8DDD3);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Typography
  static const double fontSizeH1 = 24.0;
  static const double fontSizeH2 = 20.0;
  static const double fontSizeH3 = 18.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeSmall = 10.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  // ThemeData
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: fontSizeH1, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: fontSizeH2, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: fontSizeH3, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: fontSizeBody),
        bodyMedium: TextStyle(fontSize: fontSizeBody),
        bodySmall: TextStyle(fontSize: fontSizeCaption),
        labelSmall: TextStyle(fontSize: fontSizeSmall),
      ),
    );
  }
}
