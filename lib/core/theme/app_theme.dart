import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const correct = Color(0xFF19B394);
  static const present = Color(0xFFFFB020);
  static const absent = Color(0xFF6B7085);
  static const tileBorder = Color(0xFFD3D6DA);
  static const keyDefault = Color(0xFFD3D6DA);
  static const absentKey = Color(0xFF3F4256);
  static const coinGold = Color(0xFFF5B301);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF5B3FD9),
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF5B3FD9),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121213),
    );
  }
}
