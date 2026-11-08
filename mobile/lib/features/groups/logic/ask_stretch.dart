import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';

/// An ask's pace is a stretch of the pace axis in seconds per km (D127). These two
/// bounds also mean "open ended" (the API's `LeaderMessage::OPEN_FAST` and
/// `OPEN_SLOW`): a fast edge of [askOpenFast] is "faster than the slow edge", a slow
/// edge of [askOpenSlow] is "slower than the fast edge", and both is any pace.
const askOpenFast = 150;
const askOpenSlow = 900;

/// [sPerKm] as whole seconds per [unit], to the nearest 5 s (so 9:30/mi, not 9:29).
int stretchEdge(num sPerKm, DistUnit unit) =>
    ((sPerKm * unit.kmPerUnit) / 5).round() * 5;

String _clock(int seconds) => Pace(seconds, DistUnit.mi).format();

/// What an ask is looking for, in [unit]: "a group between 9:30 and 10:15/mi",
/// "a group faster than 8:30/mi", "a group slower than 11:30/mi". Null when there
/// is no stretch (the whole run) or it is open at both ends.
String? stretchPhrase({
  required int? fastSPerKm,
  required int? slowSPerKm,
  required DistUnit unit,
}) {
  if (fastSPerKm == null || slowSPerKm == null) return null;
  final openFast = fastSPerKm <= askOpenFast;
  final openSlow = slowSPerKm >= askOpenSlow;
  final code = unit.code;
  if (openFast && openSlow) return null;
  if (openFast) {
    return 'a group faster than ${_clock(stretchEdge(slowSPerKm, unit))}/$code';
  }
  if (openSlow) {
    return 'a group slower than ${_clock(stretchEdge(fastSPerKm, unit))}/$code';
  }
  return 'a group between ${_clock(stretchEdge(fastSPerKm, unit))} and '
      '${_clock(stretchEdge(slowSPerKm, unit))}/$code';
}

/// The middle of a closed stretch as a pace in [unit], whole 5 s, for "Use 9:50/mi".
/// Null for an open-ended or missing stretch.
Pace? stretchMiddle({
  required int? fastSPerKm,
  required int? slowSPerKm,
  required DistUnit unit,
}) {
  if (fastSPerKm == null || slowSPerKm == null) return null;
  if (fastSPerKm <= askOpenFast || slowSPerKm >= askOpenSlow) return null;
  final mid = (fastSPerKm + slowSPerKm) / 2;
  return Pace(stretchEdge(mid, unit), unit);
}
