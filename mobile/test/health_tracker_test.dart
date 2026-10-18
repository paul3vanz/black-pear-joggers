import 'package:bpj/core/diagnostics/health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late HealthTracker tracker;

  setUp(() {
    now = DateTime.utc(2026, 10, 17, 9);
    tracker = HealthTracker(now: () => now);
  });

  void tick([int seconds = 5]) => now = now.add(Duration(seconds: seconds));

  test('three same-class failures are not enough, four are', () {
    for (var i = 0; i < 3; i++) {
      tracker.reportApiFailure('5xx');
      tick();
    }
    expect(tracker.state.unhealthy, isFalse);
    tracker.reportApiFailure('5xx');
    expect(tracker.state.unhealthy, isTrue);
  });

  test('different classes do not add up', () {
    for (final c in ['5xx', 'local:TypeError', '5xx', 'local:TypeError']) {
      tracker.reportApiFailure(c);
      tick();
    }
    expect(tracker.state.unhealthy, isFalse);
  });

  test('a success resets the run', () {
    for (var i = 0; i < 3; i++) {
      tracker.reportApiFailure('5xx');
    }
    tracker.reportApiSuccess();
    tracker.reportApiFailure('5xx');
    expect(tracker.state.unhealthy, isFalse);
  });

  test('a success clears an unhealthy state caused by the API', () {
    for (var i = 0; i < 4; i++) {
      tracker.reportApiFailure('5xx');
    }
    expect(tracker.state.unhealthy, isTrue);
    tracker.reportApiSuccess();
    expect(tracker.state.unhealthy, isFalse);
  });

  test('failures older than two minutes do not count', () {
    for (var i = 0; i < 3; i++) {
      tracker.reportApiFailure('5xx');
    }
    tick(121);
    tracker.reportApiFailure('5xx');
    expect(tracker.state.unhealthy, isFalse);
  });

  test('three local exceptions trip it; a database success clears them', () {
    tracker
      ..reportLocalError()
      ..reportLocalError();
    expect(tracker.state.unhealthy, isFalse);
    tracker.reportLocalError();
    expect(tracker.state.unhealthy, isTrue);
    tracker.reportLocalOk();
    expect(tracker.state.unhealthy, isFalse);
  });

  test('an API success does not hide local exceptions', () {
    tracker
      ..reportLocalError()
      ..reportLocalError()
      ..reportApiSuccess()
      ..reportLocalError();
    expect(tracker.state.unhealthy, isTrue);
  });

  test('reset() clears everything', () {
    for (var i = 0; i < 4; i++) {
      tracker.reportApiFailure('5xx');
    }
    tracker.reset();
    expect(tracker.state.unhealthy, isFalse);
    tracker.reportApiFailure('5xx');
    expect(tracker.state.unhealthy, isFalse);
  });
}
