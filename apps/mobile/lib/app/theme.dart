import 'package:flutter/material.dart';

abstract final class IslandColors {
  static const background = Color(0xFFFAF7EE);
  static const surface = Color(0xFFFFFEFA);
  static const ink = Color(0xFF294958);
  static const muted = Color(0xFF5C737D);
  static const blue = Color(0xFF2987AD);
  static const soft = Color(0xFFE9F5F6);
  static const sand = Color(0xFFF3EAD3);
  static const border = Color(0xFFE8E8DC);
}

ThemeData islandTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: IslandColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: IslandColors.blue,
    surface: IslandColors.surface,
    brightness: Brightness.light,
  ),
  fontFamily: 'BeVietnamPro',
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: IslandColors.ink,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: IslandColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: IslandColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: IslandColors.ink, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: IslandColors.muted, height: 1.5),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: IslandColors.blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: IslandColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IslandColors.border),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
);
