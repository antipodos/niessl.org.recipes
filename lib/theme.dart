import 'package:flutter/material.dart';

// Warm terracotta seed — evokes food, warmth, and appetite.
const _seedColor = Color(0xFFB85C38);

// Warm off-white surface for light mode — harmonises with terracotta.
const _warmCreamSurface = Color(0xFFF5EFE7);

// Warm dark brown surface for dark mode — matches light mode intent.
const _warmDarkSurface = Color(0xFF2B1F1A);

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  ).copyWith(surface: _warmCreamSurface),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ).copyWith(surface: _warmDarkSurface),
);
