import 'dist_unit.dart';

/// A running pace: whole seconds per [unit], as entered (D21). `9:30` per mile is
/// `Pace(570, DistUnit.mi)`. It only converts for display and matching.
class Pace implements Comparable<Pace> {
  const Pace(this.seconds, this.unit);

  /// Server limits for a stored pace (3:00 to 30:00).
  static const minSeconds = 180;
  static const maxSeconds = 1800;

  /// Seconds per [unit]. Smaller is faster.
  final int seconds;
  final DistUnit unit;

  /// Parses `m:ss` or `mm:ss` (seconds must be two digits and below 60).
  /// Throws [FormatException] otherwise. It does not apply the server's 3:00 to
  /// 30:00 limit; see [isWithinServerRange].
  factory Pace.parse(String text, DistUnit unit) {
    final pace = tryParse(text, unit);
    if (pace == null) {
      throw FormatException('Pace must look like 9:30', text);
    }
    return pace;
  }

  static final _format = RegExp(r'^(\d{1,2}):(\d{2})$');

  /// Like [Pace.parse] but returns null instead of throwing.
  static Pace? tryParse(String? text, DistUnit unit) {
    final match = _format.firstMatch(text?.trim() ?? '');
    if (match == null) return null;
    final minutes = int.parse(match.group(1)!);
    final secs = int.parse(match.group(2)!);
    if (secs >= 60) return null;
    return Pace(minutes * 60 + secs, unit);
  }

  /// Whether the server will accept this pace (180 to 1800 seconds).
  bool get isWithinServerRange =>
      seconds >= minSeconds && seconds <= maxSeconds;

  /// `9:30` (no unit).
  String format() {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// `9:30/mi`.
  String formatWithUnit() => '${format()}/${unit.code}';

  /// Seconds per kilometre, unrounded. Used for sorting and matching.
  double get secondsPerKm => seconds / unit.kmPerUnit;

  /// The same pace in [target], rounded to the nearest second.
  Pace convertTo(DistUnit target) {
    if (target == unit) return this;
    return Pace((secondsPerKm * target.kmPerUnit).round(), target);
  }

  /// True when this pace is faster (fewer seconds per km) than [other].
  bool isFasterThan(Pace other) => secondsPerKm < other.secondsPerKm;

  bool isSlowerThan(Pace other) => secondsPerKm > other.secondsPerKm;

  /// Orders fastest first, across units.
  @override
  int compareTo(Pace other) => secondsPerKm.compareTo(other.secondsPerKm);

  @override
  bool operator ==(Object other) =>
      other is Pace && other.seconds == seconds && other.unit == unit;

  @override
  int get hashCode => Object.hash(seconds, unit);

  @override
  String toString() => 'Pace(${formatWithUnit()})';
}
