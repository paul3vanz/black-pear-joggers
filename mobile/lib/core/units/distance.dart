import 'dist_unit.dart';

/// A distance as entered: a value plus its [unit] (`3` + `mi` stays 3 miles and
/// never turns into 4.83 km). It only converts for display and matching.
class Distance {
  const Distance(this.value, this.unit);

  /// Server limits for a stored distance value (in its own unit).
  static const minValue = 0.1;
  static const maxValue = 200.0;

  final double value;
  final DistUnit unit;

  /// Parses `5` or `5.5` (a comma decimal separator is accepted too). Throws
  /// [FormatException] for anything else, zero or negative values.
  factory Distance.parse(String text, DistUnit unit) {
    final d = tryParse(text, unit);
    if (d == null) {
      throw FormatException('Distance must be a number like 5 or 5.5', text);
    }
    return d;
  }

  static final _format = RegExp(r'^\d+(?:[.,]\d+)?$');

  static Distance? tryParse(String? text, DistUnit unit) {
    final t = text?.trim() ?? '';
    if (!_format.hasMatch(t)) return null;
    final value = double.parse(t.replaceAll(',', '.'));
    if (value <= 0) return null;
    return Distance(value, unit);
  }

  /// Whether the server will accept this value (0.1 to 200).
  bool get isWithinServerRange => value >= minValue && value <= maxValue;

  /// Canonical metres, for sorting and matching.
  double get metres => value * unit.metres;

  /// The same distance in [target] (unrounded).
  Distance convertTo(DistUnit target) {
    if (target == unit) return this;
    return Distance(metres / target.metres, target);
  }

  /// At most one decimal place, no trailing `.0`: `3`, `4.8`, `5.5`.
  static String formatValue(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }

  /// `3 mi` (own unit, rounded for display).
  String format() => '${formatValue(value)} ${unit.code}';

  /// In the viewer's unit, with the original in brackets when it differs:
  /// `4.8 km (3 mi)`, or just `3 mi` when the units match.
  String display(DistUnit viewerUnit) {
    if (viewerUnit == unit) return format();
    return '${convertTo(viewerUnit).format()} (${format()})';
  }

  @override
  bool operator ==(Object other) =>
      other is Distance && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => 'Distance(${format()})';
}
