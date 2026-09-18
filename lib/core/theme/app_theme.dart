import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const correct = Color(0xFF6AAA64);
  static const present = Color(0xFFC9B458);
  static const absent = Color(0xFF787C7E);
  static const tileBorder = Color(0xFFD3D6DA);
  static const keyDefault = Color(0xFFD3D6DA);
  static const coinGold = Color(0xFFF5B301);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.correct,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.correct,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121213),
    );
  }
}
