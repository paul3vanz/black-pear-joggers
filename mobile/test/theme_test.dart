import 'dart:math' as math;

import 'package:bpj/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// True when the colour is clearly warm/brown (red much higher than blue).
bool _brownish(Color c) => (c.r - c.b).abs() > 0.08;

void main() {
  for (final entry in {
    'light': BpjTheme.light,
    'dark': BpjTheme.dark,
  }.entries) {
    group('${entry.key} theme', () {
      final scheme = entry.value.colorScheme;

      test('primary is the club orange with black on-primary', () {
        expect(scheme.primary, const Color(0xFFF89829));
        expect(scheme.onPrimary, const Color(0xFF000000));
        expect(_contrast(scheme.primary, scheme.onPrimary), greaterThan(7));
      });

      test('text pairs keep AA contrast', () {
        expect(_contrast(scheme.surface, scheme.onSurface), greaterThan(7));
        expect(
          _contrast(scheme.surface, scheme.onSurfaceVariant),
          greaterThan(4.5),
        );
        expect(
          _contrast(scheme.secondary, scheme.onSecondary),
          greaterThan(4.5),
        );
        expect(
          _contrast(scheme.primaryContainer, scheme.onPrimaryContainer),
          greaterThan(4.5),
        );
      });

      test('surfaces are neutral greys, not brown', () {
        for (final c in [
          scheme.surface,
          scheme.surfaceContainer,
          scheme.surfaceContainerHigh,
          scheme.secondaryContainer,
          scheme.onSurface,
          scheme.outline,
        ]) {
          expect(_brownish(c), isFalse, reason: '$c looks warm');
        }
      });
    });
  }

  test('button themes are built and filled buttons keep their height', () {
    final size = BpjTheme.light.filledButtonTheme.style!.minimumSize!.resolve(
      <WidgetState>{},
    );
    expect(size!.height, 52);
    expect(BpjTheme.dark.brightness, Brightness.dark);
  });
}
