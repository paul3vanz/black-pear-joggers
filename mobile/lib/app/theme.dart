import 'package:flutter/material.dart';

/// BPJ brand palette. Club colours are white, black and orange (D51): the orange is the
/// club website's `#f89829`, everything else is a neutral black-to-grey scale (no browns).
abstract final class BpjColors {
  /// The brand orange (bpj.org.uk).
  static const orange = Color(0xFFF89829);

  /// Darker orange for orange *text* on white, where [orange] itself is too light
  /// (4.9:1 contrast instead of 2.2:1).
  static const orangeText = Color(0xFFB56406);

  /// Pale orange tint for containers / selected chips in the light theme.
  static const orangeTint = Color(0xFFFDE4C7);

  /// Deep orange-tinted container for the dark theme.
  static const orangeDeep = Color(0xFF5C3407);

  // Neutral scale, black to white.
  static const black = Color(0xFF000000);
  static const neutral950 = Color(0xFF0A0A0A);
  static const neutral900 = Color(0xFF171717);
  static const neutral850 = Color(0xFF1F1F1F);
  static const neutral800 = Color(0xFF262626);
  static const neutral700 = Color(0xFF404040);
  static const neutral600 = Color(0xFF525252);
  static const neutral500 = Color(0xFF737373);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral50 = Color(0xFFFAFAFA);
  static const white = Color(0xFFFFFFFF);
}

/// Material 3 themes. React/TS equivalent: a Tailwind/MUI theme object, passed once to
/// `MaterialApp` and read anywhere with `Theme.of(context)` (like `useTheme()`).
///
/// The `ColorScheme`s are spelled out in full instead of `ColorScheme.fromSeed`, because
/// seeding from orange tints every surface brown/cream. Orange backgrounds carry black text.
abstract final class BpjTheme {
  static final light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: BpjColors.orange,
      onPrimary: BpjColors.black,
      primaryContainer: BpjColors.orangeTint,
      onPrimaryContainer: BpjColors.neutral900,
      secondary: BpjColors.neutral800,
      onSecondary: BpjColors.white,
      secondaryContainer: BpjColors.neutral200,
      onSecondaryContainer: BpjColors.neutral900,
      tertiary: BpjColors.neutral600,
      onTertiary: BpjColors.white,
      tertiaryContainer: BpjColors.neutral100,
      onTertiaryContainer: BpjColors.neutral900,
      error: Color(0xFFB3261E),
      onError: BpjColors.white,
      surface: BpjColors.white,
      onSurface: BpjColors.neutral900,
      onSurfaceVariant: BpjColors.neutral600,
      surfaceDim: BpjColors.neutral200,
      surfaceBright: BpjColors.white,
      surfaceContainerLowest: BpjColors.white,
      surfaceContainerLow: BpjColors.neutral50,
      surfaceContainer: BpjColors.neutral100,
      surfaceContainerHigh: BpjColors.neutral200,
      surfaceContainerHighest: BpjColors.neutral300,
      outline: BpjColors.neutral500,
      outlineVariant: BpjColors.neutral300,
      shadow: BpjColors.black,
      scrim: BpjColors.black,
      inverseSurface: BpjColors.neutral800,
      onInverseSurface: BpjColors.neutral100,
      inversePrimary: BpjColors.orange,
      surfaceTint: BpjColors
          .white, // no tint: M3 would otherwise colour elevated surfaces
    ),
    // Orange text/links on white need the darker shade.
    linkColor: BpjColors.orangeText,
  );

  static final dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: BpjColors.orange,
      onPrimary: BpjColors.black,
      primaryContainer: BpjColors.orangeDeep,
      onPrimaryContainer: BpjColors.orangeTint,
      secondary: BpjColors.neutral200,
      onSecondary: BpjColors.neutral900,
      secondaryContainer: BpjColors.neutral700,
      onSecondaryContainer: BpjColors.neutral100,
      tertiary: BpjColors.neutral400,
      onTertiary: BpjColors.neutral900,
      tertiaryContainer: BpjColors.neutral800,
      onTertiaryContainer: BpjColors.neutral100,
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: BpjColors.neutral950,
      onSurface: BpjColors.neutral100,
      onSurfaceVariant: BpjColors.neutral400,
      surfaceDim: BpjColors.black,
      surfaceBright: BpjColors.neutral700,
      surfaceContainerLowest: BpjColors.black,
      surfaceContainerLow: BpjColors.neutral900,
      surfaceContainer: BpjColors.neutral850,
      surfaceContainerHigh: BpjColors.neutral800,
      surfaceContainerHighest: BpjColors.neutral700,
      outline: BpjColors.neutral500,
      outlineVariant: BpjColors.neutral700,
      shadow: BpjColors.black,
      scrim: BpjColors.black,
      inverseSurface: BpjColors.neutral100,
      onInverseSurface: BpjColors.neutral900,
      inversePrimary: BpjColors.orangeText,
      surfaceTint: BpjColors.neutral950,
    ),
    linkColor: BpjColors.orange,
  );

  static ThemeData _build(ColorScheme scheme, {required Color linkColor}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [
        scheme.brightness == Brightness.dark
            ? RunFeedColors.dark
            : RunFeedColors.light,
      ],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      // Text buttons are orange *text*, so use the shade that reads on the surface.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: linkColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: linkColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: BpjColors.orange,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? BpjColors.black
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: BpjColors.orange,
          selectedForegroundColor: BpjColors.black,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: BpjColors.orange,
        textColor: BpjColors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BpjColors.black : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BpjColors.orange : null,
        ),
      ),
    );
  }
}

/// Colours for the Runs feed (D117) that the `ColorScheme` has no slot for.
/// The dark values are the ones in the run feed design; the light ones keep
/// the same roles with readable contrast on white.
@immutable
class RunFeedColors extends ThemeExtension<RunFeedColors> {
  const RunFeedColors({
    required this.followingOutline,
    required this.bannerFill,
    required this.bannerBorder,
    required this.bannerText,
    required this.hiddenFill,
    required this.hiddenBorder,
    required this.hiddenText,
  });

  /// Outline of the Following chip.
  final Color followingOutline;

  /// The All runs "Just looking" banner (dashed border = temporary).
  final Color bannerFill;
  final Color bannerBorder;
  final Color bannerText;

  /// A hidden run's card in All runs (dimmed).
  final Color hiddenFill;
  final Color hiddenBorder;
  final Color hiddenText;

  static const dark = RunFeedColors(
    followingOutline: Color(0xFF8A5A1E),
    bannerFill: Color(0xFF1A1308),
    bannerBorder: Color(0xFF8A5A1E),
    bannerText: Color(0xFFE8D5BC),
    hiddenFill: Color(0xFF121212),
    hiddenBorder: Color(0xFF232323),
    hiddenText: Color(0xFF8F8F8F),
  );

  static const light = RunFeedColors(
    followingOutline: BpjColors.orangeText,
    bannerFill: Color(0xFFFFF6EA),
    bannerBorder: BpjColors.orangeText,
    bannerText: BpjColors.orangeDeep,
    hiddenFill: BpjColors.neutral100,
    hiddenBorder: BpjColors.neutral200,
    hiddenText: BpjColors.neutral500,
  );

  static RunFeedColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<RunFeedColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  RunFeedColors copyWith() => this;

  @override
  RunFeedColors lerp(RunFeedColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
