// The club standards document, `GET /app/clubs/{clubId}/standards` (Phase 9).
// Parsing is deliberately tolerant: a missing optional field becomes a default
// instead of throwing, so a server that adds or drops a field never blanks the
// screen. (TS equivalent: a zod schema full of `.optional().default(...)`.)

import '../logic/standards_format.dart';

/// An int, a double or a numeric string as a double; null for anything else.
double? _double(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

/// Whole seconds from an int, a double or a numeric string; null if unusable.
int? _int(Object? v) => _double(v)?.round();

/// A non-empty string, else null.
String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// One event of the scheme (`Mile`, `5K`...), with its distance in metres.
class StandardsEvent {
  const StandardsEvent({required this.name, required this.distanceM});

  final String name;

  /// Metres. The server sends an int (`5000`) or a double (`1609.34`).
  final double distanceM;

  static StandardsEvent? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = _str(json['event']);
    final distance = _double(json['distanceM']);
    if (name == null || distance == null || distance <= 0) return null;
    return StandardsEvent(name: name, distanceM: distance);
  }
}

/// One standard: the time needed for [award] in [event] for a gender and
/// category.
class StandardsItem {
  const StandardsItem({
    required this.gender,
    required this.category,
    required this.event,
    required this.award,
    required this.time,
    this.timeS,
  });

  /// `male` or `female`.
  final String gender;
  final String category;
  final String event;
  final String award;

  /// The time as the server stores it (`25:48`, `1:58:26`).
  final String time;

  /// The same in whole seconds; null if the server could not work it out.
  final int? timeS;

  static StandardsItem? tryParse(Object? json) {
    if (json is! Map) return null;
    final gender = _str(json['gender']);
    final category = _str(json['category']);
    final event = _str(json['event']);
    final award = _str(json['award']);
    if (gender == null || category == null || event == null || award == null) {
      return null;
    }
    final timeS = _int(json['timeS']);
    // Neither a time nor seconds: nothing to show.
    final time =
        _str(json['time']) ?? (timeS == null ? null : formatRaceTime(timeS));
    if (time == null) return null;
    return StandardsItem(
      gender: gender,
      category: category,
      event: event,
      award: award,
      time: time,
      timeS: timeS,
    );
  }
}

/// The caller's own gender and category, from their athlete record.
class MyCategory {
  const MyCategory({required this.gender, required this.category});

  final String gender;
  final String category;

  static MyCategory? tryParse(Object? json) {
    if (json is! Map) return null;
    final gender = _str(json['gender']);
    final category = _str(json['category']);
    if (gender == null || category == null) return null;
    return MyCategory(gender: gender, category: category);
  }

  @override
  bool operator ==(Object other) =>
      other is MyCategory &&
      other.gender == gender &&
      other.category == category;

  @override
  int get hashCode => Object.hash(gender, category);
}

/// The whole document.
class StandardsData {
  const StandardsData({
    required this.awards,
    required this.events,
    required this.categories,
    required this.items,
    this.mine,
    this.updatedAt,
  });

  /// Award names, lowest first (Bronze ... Platinum): the column order.
  final List<String> awards;

  /// Events that have standards, shortest first.
  final List<StandardsEvent> events;

  /// Categories per gender (`male` / `female`), youngest first.
  final Map<String, List<String>> categories;
  final List<StandardsItem> items;

  /// Null when the server does not know the caller's gender or category.
  final MyCategory? mine;
  final DateTime? updatedAt;

  factory StandardsData.fromJson(Map<String, Object?> json) {
    final categories = <String, List<String>>{};
    final rawCategories = json['categories'];
    if (rawCategories is Map) {
      for (final entry in rawCategories.entries) {
        final list = entry.value;
        if (list is List) {
          categories['${entry.key}'] = [
            for (final c in list)
              if (_str(c) != null) c! as String,
          ];
        }
      }
    }
    return StandardsData(
      awards: [
        for (final a in json['awards'] as List<Object?>? ?? const [])
          if (_str(a) != null) a! as String,
      ],
      events: [
        for (final e in json['events'] as List<Object?>? ?? const [])
          ?StandardsEvent.tryParse(e),
      ],
      categories: categories,
      items: [
        for (final i in json['items'] as List<Object?>? ?? const [])
          ?StandardsItem.tryParse(i),
      ],
      mine: MyCategory.tryParse(json['mine']),
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt']! as String)
          : null,
    );
  }

  /// The categories to offer for [gender] (empty if the table has none).
  List<String> categoriesFor(String gender) =>
      categories[gender] ?? const <String>[];

  /// The standards of [gender] and [category] by event name then award name.
  Map<String, Map<String, StandardsItem>> tableFor(
    String gender,
    String category,
  ) {
    final table = <String, Map<String, StandardsItem>>{};
    for (final item in items) {
      if (item.gender == gender && item.category == category) {
        (table[item.event] ??= {})[item.award] = item;
      }
    }
    return table;
  }
}
