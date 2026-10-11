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
  test('fetch parses the cap and series', () async {
    final adapter = FakeAdapter({
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(),
      ),
    });
    final s = await NotificationSettingsRepository(fakeDio(adapter)).fetch(1);
    expect(s.dailyPushCap, 6);
    expect(s.defaultDailyPushCap, 6);
    expect(s.series.map((r) => r.seriesId), ['s-tue', 's-thu']);
    expect(s.series.first.weekday, 2);
    expect(s.series.first.localStartTime, '19:00');
    expect(s.series.first.reminders, ReminderMode.auto);
    expect(s.series.last.reminders, ReminderMode.off);
  });

  test('unknown reminder values fall back to automatic; 0 cap is kept', () {
    final s = NotificationSettings.fromJson({
      ...settingsJson(cap: 0, tuesday: 'weird'),
    });
    expect(s.dailyPushCap, 0);
    expect(s.series.first.reminders, ReminderMode.auto);
  });

  test('update sends only the cap, or only the changed series', () async {
    final adapter = FakeAdapter({
      'PUT /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(cap: 12, tuesday: 'on'),
      ),
    });
    final repo = NotificationSettingsRepository(fakeDio(adapter));

    final first = await repo.update(1, dailyPushCap: 12);
    expect(adapter.requests.last.data, {'dailyPushCap': 12});
    expect(first.dailyPushCap, 12);

    final second = await repo.update(1, series: {'s-tue': ReminderMode.on});
    expect(adapter.requests.last.data, {
      'series': {'s-tue': 'on'},
    });
    expect(second.series.first.reminders, ReminderMode.on);

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

  test('copyWith changes only the named series', () {
    final s = NotificationSettings.fromJson(settingsJson())
        .copyWith(dailyPushCap: 3, series: {'s-thu': ReminderMode.on});
    expect(s.dailyPushCap, 3);
    expect(s.series.first.reminders, ReminderMode.auto);
    expect(s.series.last.reminders, ReminderMode.on);
  });
}
