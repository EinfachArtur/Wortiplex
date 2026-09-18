import 'package:flutter/material.dart';

import 'game_style.dart';

/// Colours of the letter tiles and keyboard keys.
class AppColors {
  const AppColors._();

  static const correct = Color(0xFF19B394);
  static const present = Color(0xFFFFB020);
  static const absent = Color(0xFF59607A);
  static const absentKey = Color(0xFF3F4256);
  static const tileEmpty = Color(0x14FFFFFF);
  static const tileBorder = Color(0x40FFFFFF);
  static const keyDefault = Color(0x33FFFFFF);
}

/// The whole app uses one dark "night sky" theme.
class AppTheme {
  const AppTheme._();

  static ThemeData game() {
    const scheme = ColorScheme.dark(
      primary: GameColors.mint,
      onPrimary: GameColors.night0,
      secondary: GameColors.amber,
      onSecondary: GameColors.night0,
      tertiary: GameColors.violet,
      error: GameColors.coral,
      surface: GameColors.night0,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF2E2470),
      onSurfaceVariant: GameColors.textDim,
      outline: GameColors.glassBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: kGameFont,
      scaffoldBackgroundColor: GameColors.night0,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3B2A8C),
        contentTextStyle: gameText(15, weight: 600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C1C6E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: gameText(22),
        contentTextStyle: gameText(16, weight: 500),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    );
  }
}
