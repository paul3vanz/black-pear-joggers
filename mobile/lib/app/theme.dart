import 'package:flutter/material.dart';

/// BPJ brand palette, copied from `primary` in `next/tailwind.config.js`
/// (the website's Tailwind theme) so the app matches bpj.org.uk.
abstract final class BpjColors {
  static const primary50 = Color(0xFFFEEEDB);
  static const primary100 = Color(0xFFFDE4C7);
  static const primary200 = Color(0xFFFCD1A0);
  static const primary300 = Color(0xFFFBBE78);
  static const primary400 = Color(0xFFF9AB51);
  static const primary500 = Color(0xFFF89829); // the brand orange
  static const primary600 = Color(0xFFE67F08);
  static const primary700 = Color(0xFFB56406);
  static const primary800 = Color(0xFF844904);
  static const primary900 = Color(0xFF522D03);
}

/// Material 3 themes. React/TS equivalent: a Tailwind/MUI theme object, passed once to
/// `MaterialApp` and read anywhere with `Theme.of(context)` (like `useTheme()`).
abstract final class BpjTheme {
  // The raw brand orange (#F89829) is too light for white text, so the light scheme
  // uses the darker 700 shade for `primary` and keeps the pale shades for containers.
  // `fromSeed` derives the neutral/secondary/tertiary tones; we then pin the primaries.
  static final light = _build(
    ColorScheme.fromSeed(
      seedColor: BpjColors.primary500,
      brightness: Brightness.light,
    ).copyWith(
      primary: BpjColors.primary700,
      onPrimary: Colors.white,
      primaryContainer: BpjColors.primary100,
      onPrimaryContainer: BpjColors.primary900,
    ),
  );

  static final dark = _build(
    ColorScheme.fromSeed(
      seedColor: BpjColors.primary500,
      brightness: Brightness.dark,
    ).copyWith(
      primary: BpjColors.primary400,
      onPrimary: BpjColors.primary900,
      primaryContainer: BpjColors.primary800,
      onPrimaryContainer: BpjColors.primary100,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
