import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';

/// A race time in whole [seconds]: `25:48` under an hour, `1:58:26` from an
/// hour up. (`formatClock` is for times of day, so it does not apply.)
String formatRaceTime(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h == 0 ? '$m:$sec' : '$h:${m.toString().padLeft(2, '0')}:$sec';
}

/// The pace needed to cover [distanceM] metres in [timeS] seconds, per [unit],
/// rounded to the nearest second. 25:48 over 5000 m is `8:18/mi` and `5:10/km`.
/// (The website floors the seconds; the nearest second is closer to the truth.)
Pace paceForTime(int timeS, double distanceM, DistUnit unit) =>
    Pace((timeS / distanceM * unit.metres).round(), unit);

/// `8:18/mi` for the same inputs.
String formatRacePace(int timeS, double distanceM, DistUnit unit) =>
    paceForTime(timeS, distanceM, unit).formatWithUnit();
