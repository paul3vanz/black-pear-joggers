import 'package:flutter/material.dart';

/// The tint of one award tile: [background] and [foreground] (text, at least
/// 7:1 apart) and a medal [accent] for the icon.
class MedalStyle {
  const MedalStyle(this.background, this.foreground, this.accent);

  final Color background;
  final Color foreground;
  final Color accent;
}

/// Bronze, silver, gold and platinum tints that sit on the app's black, white
/// and orange palette: pale tints with dark text in the light theme, deep tints
/// with pale text in the dark one. Silver is neutral grey and platinum a cool
/// blue-grey so the two stay apart. An award the app does not know gets the
/// neutral surface colours.
MedalStyle medalStyle(BuildContext context, String award) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (award.toLowerCase()) {
    'bronze' =>
      dark
          ? const MedalStyle(
              Color(0xFF4A3322),
              Color(0xFFF3DFCB),
              Color(0xFFD08A4E),
            )
          : const MedalStyle(
              Color(0xFFF3DFCB),
              Color(0xFF3F250C),
              Color(0xFFA65F1F),
            ),
    'silver' =>
      dark
          ? const MedalStyle(
              Color(0xFF3A3D42),
              Color(0xFFE6E8EB),
              Color(0xFFB4BAC2),
            )
          : const MedalStyle(
              Color(0xFFE6E8EB),
              Color(0xFF24282C),
              Color(0xFF7D858E),
            ),
    'gold' =>
      dark
          ? const MedalStyle(
              Color(0xFF4D3E0A),
              Color(0xFFFBE9A6),
              Color(0xFFE8B923),
            )
          : const MedalStyle(
              Color(0xFFFBE9A6),
              Color(0xFF3F3000),
              Color(0xFFB88700),
            ),
    'platinum' =>
      dark
          ? const MedalStyle(
              Color(0xFF263747),
              Color(0xFFDDE8F0),
              Color(0xFF8FB8D6),
            )
          : const MedalStyle(
              Color(0xFFDDE8F0),
              Color(0xFF14262F),
              Color(0xFF4C84A8),
            ),
    _ => () {
      final scheme = Theme.of(context).colorScheme;
      return MedalStyle(
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        scheme.onSurfaceVariant,
      );
    }(),
  };
}
