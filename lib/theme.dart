import 'package:flutter/material.dart';

/// Minimal app theme using the bundled Doto font to avoid fetching remote fonts on web.
class AppTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Doto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF174659),
      foregroundColor: Colors.white,
      elevation: 8,
      centerTitle: true,
    ),
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    fontFamily: 'Doto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF174659),
      foregroundColor: Colors.white,
      elevation: 8,
      centerTitle: true,
    ),
  );
}
