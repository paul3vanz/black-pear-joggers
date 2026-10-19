import 'fake_api.dart';

/// One `GET /follows` series entry (D117).
Map<String, Object?> followJson(
  String seriesId, {
  String title = 'Monday club run',
  int weekday = 1,
  String start = '19:00',
  String mode = 'auto',
  bool usuallyComes = false,
  String groupMode = 'paced',
}) => {
  'seriesId': seriesId,
  'title': title,
  'weekday': weekday,
  'localStartTime': start,
  'groupMode': groupMode,
  'mode': mode,
  'usuallyComes': usuallyComes,
  'followed': mode == 'follow' || (mode == 'auto' && usuallyComes),
};

/// A tiny in-memory `/follows` server: GET, PUT one and PUT many (both body
/// forms), like the API. Set [fail] to make every PUT answer 503.
class FakeFollowsServer {
  FakeFollowsServer(List<Map<String, Object?>> series)
    : series = [for (final s in series) Map.of(s)];

  final List<Map<String, Object?>> series;
  bool fail = false;

  Map<String, Object?> _find(String id) =>
      series.firstWhere((s) => s['seriesId'] == id);

  void _set(String id, String mode) {
    final s = _find(id);
    s['mode'] = mode;
    s['followed'] =
        mode == 'follow' || (mode == 'auto' && s['usuallyComes'] == true);
  }

  /// Routes for a [FakeAdapter], under `/app/clubs/1`. [lastBody] reads the
  /// request being answered.
  Map<String, Object> routes(Object? Function() lastBody) => {
    'GET /app/clubs/1/follows': () => FakeResponse(200, {'series': series}),
    'PUT /app/clubs/1/follows': () {
      if (fail) return const FakeResponse(503, {'error': 'unavailable'});
      final body = Map<String, Object?>.from(lastBody()! as Map);
      final modes = body.containsKey('modes')
          ? Map<String, Object?>.from(body['modes']! as Map)
                .map((k, v) => MapEntry(k, v! as String))
          : {
              for (final id in (body['seriesIds']! as List).cast<String>())
                id: body['mode']! as String,
            };
      final previous = {for (final id in modes.keys) id: _find(id)['mode']};
      modes.forEach(_set);
      return FakeResponse(200, {'previous': previous, 'series': series});
    },
    for (final s in series)
      'PUT /app/clubs/1/follows/${s['seriesId']}': () {
        if (fail) return const FakeResponse(503, {'error': 'unavailable'});
        final body = Map<String, Object?>.from(lastBody()! as Map);
        _set(s['seriesId']! as String, body['mode']! as String);
        return FakeResponse(200, _find(s['seriesId']! as String));
      },
  };
}
