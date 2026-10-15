// Phase 9 fixtures matching docs/api-contract.md ("Phase 9: club standards").

Map<String, Object?> standardsItemJson(
  String gender,
  String category,
  String event,
  String award,
  String time,
  int? timeS,
) => {
  'gender': gender,
  'category': category,
  'event': event,
  'award': award,
  'time': time,
  'timeS': timeS,
};

/// Four awards' items for one event, given `[bronze, silver, gold, platinum]`
/// times as `m:ss` / `h:mm:ss` strings (seconds are worked out here).
List<Map<String, Object?>> standardsRow(
  String gender,
  String category,
  String event,
  List<String> times,
) {
  const awards = ['Bronze', 'Silver', 'Gold', 'Platinum'];
  int seconds(String t) {
    final p = t.split(':').map(int.parse).toList();
    return p.length == 3 ? p[0] * 3600 + p[1] * 60 + p[2] : p[0] * 60 + p[1];
  }

  return [
    for (var i = 0; i < 4; i++)
      standardsItemJson(
        gender,
        category,
        event,
        awards[i],
        times[i],
        seconds(times[i]),
      ),
  ];
}

/// A small standards document: Mile, 5K and Half Marathon for male SEN and V45
/// and female SEN and V50 (female V50 has no Half Marathon standard). [mine]
/// is the caller's category or null.
Map<String, Object?> standardsJson({
  Map<String, String>? mine = const {'gender': 'female', 'category': 'V50'},
  String updatedAt = '2026-10-15T09:30:00Z',
}) => {
  'awards': ['Bronze', 'Silver', 'Gold', 'Platinum'],
  'events': [
    {'event': 'Mile', 'distanceM': 1609.34},
    {'event': '5K', 'distanceM': 5000},
    {'event': 'Half Marathon', 'distanceM': 21097.5},
  ],
  'categories': {
    'male': ['SEN', 'V45'],
    'female': ['SEN', 'V50'],
  },
  'items': [
    ...standardsRow('male', 'SEN', 'Mile', ['7:25', '6:40', '6:10', '5:40']),
    ...standardsRow('male', 'SEN', '5K', ['25:48', '23:00', '21:00', '19:10']),
    ...standardsRow('male', 'SEN', 'Half Marathon', [
      '1:58:26',
      '1:46:00',
      '1:36:00',
      '1:28:00',
    ]),
    ...standardsRow('male', 'V45', 'Mile', ['7:40', '6:55', '6:25', '5:55']),
    ...standardsRow('male', 'V45', '5K', ['26:30', '23:40', '21:40', '19:50']),
    ...standardsRow('male', 'V45', 'Half Marathon', [
      '2:00:00',
      '1:48:00',
      '1:38:00',
      '1:30:00',
    ]),
    ...standardsRow('female', 'SEN', 'Mile', ['8:30', '7:40', '7:00', '6:30']),
    ...standardsRow('female', 'SEN', '5K', [
      '29:30',
      '26:30',
      '24:00',
      '22:00',
    ]),
    ...standardsRow('female', 'SEN', 'Half Marathon', [
      '2:15:00',
      '2:02:00',
      '1:50:00',
      '1:40:00',
    ]),
    ...standardsRow('female', 'V50', 'Mile', ['9:10', '8:20', '7:35', '7:00']),
    ...standardsRow('female', 'V50', '5K', [
      '31:20',
      '28:20',
      '25:40',
      '23:40',
    ]),
  ],
  'mine': mine,
  'updatedAt': updatedAt,
};
