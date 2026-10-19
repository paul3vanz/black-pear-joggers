import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/features/settings/data/notification_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, Object?> settingsJson({
  int cap = 6,
  String tuesday = 'auto',
  String thursday = 'off',
}) => {
  'dailyPushCap': cap,
  'defaultDailyPushCap': 6,
  'series': [
    {
      'seriesId': 's-tue',
      'title': 'Tuesday run',
      'weekday': 2,
      'localStartTime': '19:00',
      'reminders': tuesday,
    },
    {
      'seriesId': 's-thu',
      'title': 'Thursday run',
      'weekday': 4,
      'localStartTime': '18:30',
      'reminders': thursday,
    },
  ],
};

void main() {
  test('fetch parses the cap (the old per-series list is ignored)', () async {
    final adapter = FakeAdapter({
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(),
      ),
    });
    final s = await NotificationSettingsRepository(fakeDio(adapter)).fetch(1);
    expect(s.dailyPushCap, 6);
    expect(s.defaultDailyPushCap, 6);
  });

  test('a 0 cap is kept; a missing cap falls back to the default', () {
    expect(NotificationSettings.fromJson(settingsJson(cap: 0)).dailyPushCap, 0);
    expect(
      NotificationSettings.fromJson({'defaultDailyPushCap': 6}).dailyPushCap,
      6,
    );
  });

  test('update sends only the cap', () async {
    final adapter = FakeAdapter({
      'PUT /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(cap: 12),
      ),
    });
    final repo = NotificationSettingsRepository(fakeDio(adapter));

    final first = await repo.update(1, dailyPushCap: 12);
    expect(adapter.requests.last.data, {'dailyPushCap': 12});
    expect(first.dailyPushCap, 12);

    await repo.update(1, dailyPushCap: 0);
    expect(adapter.requests.last.data, {'dailyPushCap': 0});
  });

  test('offline surfaces as a network ApiException', () async {
    final repo = NotificationSettingsRepository(fakeDio(FakeAdapter({})));
    await expectLater(
      repo.fetch(1),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'net', true)),
    );
  });
}
