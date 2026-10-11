/// Metres in one international mile.
const double kMetresPerMile = 1609.344;

/// Metres in one kilometre.
const double kMetresPerKm = 1000;

/// The unit a pace or a distance is entered and shown in. One enum serves both
/// ("min per mile" and "miles" are both `mi`), like a TS `type DistUnit = 'mi' | 'km'`.
enum DistUnit {
  mi('mi', kMetresPerMile),
  km('km', kMetresPerKm);

  const DistUnit(this.code, this.metres);

  /// The wire value (`"mi"` / `"km"`).
  final String code;

  /// Metres in one of this unit.
  final double metres;

  /// Kilometres in one of this unit (1 for km, 1.609344 for mi).
  double get kmPerUnit => metres / kMetresPerKm;

  /// Parses the wire value; null for null or anything unknown.
  static DistUnit? fromCode(Object? code) => switch (code) {
    'mi' => DistUnit.mi,
    'km' => DistUnit.km,
    _ => null,
  };
}
