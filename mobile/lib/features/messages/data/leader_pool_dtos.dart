import '../../../core/units/pace_spec.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// The group a pool member last led: what their usual pace is.
class PoolLastLed {
  const PoolLastLed({required this.kind, required this.pace, this.label});

  final String kind;
  final String? label;

  /// Their usual pace (a single pace, a range, or none for a jog/walk group).
  final PaceSpec pace;

  bool get isJogWalk => kind == 'jog_walk';

  factory PoolLastLed.fromJson(Map<String, Object?> json) => PoolLastLed(
    kind: json['kind'] as String? ?? 'run',
    label: json['label'] as String?,
    pace: PaceSpec.fromFields(
      unit: json['paceUnit'] as String?,
      fromS: (json['paceFromS'] as num?)?.toInt(),
      toS: (json['paceToS'] as num?)?.toInt(),
    ),
  );
}

/// One person the committee may ask to lead a run (D127), from
/// `GET …/sessions/{id}/leaders-chat/pool`.
class PoolMember {
  const PoolMember({
    required this.memberId,
    required this.name,
    required this.reason,
    required this.ledCount,
    this.lastLedOn,
    this.lastLed,
    this.fitsRange = false,
    this.leadingThisRun = false,
    this.notGoing = false,
    this.askedRecently = false,
  });

  final String memberId;
  final String name;

  /// `chose_day` | `led_series` | `led_day` | `new_leader`.
  final String reason;

  /// Runs they led (confirmed), in the window the server looks at.
  final int ledCount;

  /// The date of the latest of those, null when they never led.
  final DateTime? lastLedOn;
  final PoolLastLed? lastLed;

  /// Their usual pace is near what the committee is looking for.
  final bool fitsRange;
  final bool leadingThisRun;
  final bool notGoing;
  final bool askedRecently;

  /// Why they cannot be picked, or null when they can.
  String? get blockedReason => leadingThisRun
      ? 'Already leading'
      : notGoing
      ? "Can't make it"
      : askedRecently
      ? 'Asked recently'
      : null;

  bool get canBeAsked => blockedReason == null;

  factory PoolMember.fromJson(Map<String, Object?> json) {
    final last = json['lastLed'];
    return PoolMember(
      memberId: json['memberId']! as String,
      name: json['name'] as String? ?? 'Member',
      reason: json['reason'] as String? ?? 'led_series',
      ledCount: (json['ledCount'] as num?)?.toInt() ?? 0,
      lastLedOn: _date(json['lastLedOn']),
      lastLed: last is Map
          ? PoolLastLed.fromJson(Map<String, Object?>.from(last))
          : null,
      fitsRange: json['fitsRange'] as bool? ?? false,
      leadingThisRun: json['leadingThisRun'] as bool? ?? false,
      notGoing: json['notGoing'] as bool? ?? false,
      askedRecently: json['askedRecently'] as bool? ?? false,
    );
  }
}

/// A person an ask could not go to, and why (`leading` | `not_going` |
/// `asked_recently` | `inactive`).
class AskSkipped {
  const AskSkipped({required this.memberId, required this.reason});

  final String memberId;
  final String reason;

  factory AskSkipped.fromJson(Map<String, Object?> json) => AskSkipped(
    memberId: json['memberId'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
  );
}

/// How an ask went: how many people got it and who was left out.
typedef AskResult = ({int notified, List<AskSkipped> skipped});
