import 'package:flutter/material.dart';

class Themes {
  static const Color cream = Color.fromARGB(255, 249, 177, 122);
  static const Color grayLight = Color.fromARGB(255, 77, 83, 117);
  static const Color grayMid = Color.fromARGB(255, 56, 61, 89);
  static const Color grayDark = Color.fromARGB(255, 31, 35, 56);

  static ThemeData darkTheme = ThemeData(
    appBarTheme: const AppBarTheme(color: grayMid),
    scaffoldBackgroundColor: grayDark,
    colorScheme: const ColorScheme.dark(
      primary: cream,
      secondary: grayLight,
      tertiary: grayMid,
      background: grayDark,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: grayDark,
      selectedItemColor: cream,
      unselectedItemColor: grayLight,
    ),
  );
}
