import 'package:flutter/material.dart';

class Themes {
  static Color cream = const Color.fromARGB(255, 249, 177, 122);
  static Color grayLight = const Color.fromARGB(255, 77, 83, 117);
  static Color grayMid = const Color.fromARGB(255, 56, 61, 89);
  static Color grayDark = const Color.fromARGB(255, 31, 35, 56);

  static ThemeData darkTheme = ThemeData(
    appBarTheme: AppBarTheme(
      color: grayMid,
    ),
    scaffoldBackgroundColor: grayDark,
    colorScheme: ColorScheme.dark(
      primary: cream,
      secondary: grayLight,
      tertiary: grayMid,
      background: grayDark,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: grayMid,
      selectedItemColor: cream,
      unselectedItemColor: grayLight,
    ),
  );
}
