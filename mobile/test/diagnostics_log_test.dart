import 'dart:convert';

import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/diagnostics/redaction.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements DiagnosticsStorage {
  _MemoryStorage([this.contents]);

  String? contents;
  int writes = 0;
  bool deleted = false;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async {
    writes++;
    contents = value;
  }

  @override
  Future<void> delete() async {
    deleted = true;
    contents = null;
  }
}

const _info = ReportInfo(
  appName: 'BPJ',
  version: '1.0.0 (2)',
  platform: 'android test',
  schemaVersion: 9,
  signedIn: true,
  clubId: 1,
);

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime.utc(2026, 10, 17, 9));

  group('redaction', () {
    test('tokens, emails and login ids become [redacted]', () {
      final out = redact(
        'GET failed Bearer abc.def-123 for jo@example.com '
        'auth0|65f1a2b3c4d5 eyJhbGciOi.eyJzdWIiOi.sig_nat-ure '
        '0123456789abcdef0123456789abcdef0123',
      );
      expect(out, isNot(contains('abc.def')));
      expect(out, isNot(contains('example.com')));
      expect(out, isNot(contains('auth0|')));
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('0123456789abcdef')));
      expect(out, contains(redactedMark));
    });

    test('paths lose the query string and uuids', () {
      expect(
        safePath(
          '/app/clubs/1/sessions/123e4567-e89b-12d3-a456-426614174000'
          '?token=secret&email=a@b.co',
        ),
        '/app/clubs/1/sessions/:id',
      );
    });

    test('FormatException text (which quotes the input) is dropped', () {
      expect(
        describeError(const FormatException('Unexpected: jo@example.com')),
        'FormatException',
      );
      expect(
        describeError(PlatformException(code: 'KEYSTORE')),
        contains('KEYSTORE'),
      );
    });
  });

  group('ring buffer', () {
    test('keeps only the last 100 entries', () {
      final d = Diagnostics(now: clock);
      for (var i = 0; i < 130; i++) {
        d.record(DiagArea.ui, 'event $i');
      }
      expect(d.entries, hasLength(100));
      expect(d.entries.first.message, 'event 30');
      expect(d.entries.last.message, 'event 129');
    });

    test('identical events within 60 s collapse into a counter', () {
      final d = Diagnostics(now: clock);
      d.record(DiagArea.api, 'GET failed: network', path: '/app/me');
      now = now.add(const Duration(seconds: 30));
      d.record(DiagArea.api, 'GET failed: network', path: '/app/me');
      now = now.add(const Duration(seconds: 59));
      d.record(DiagArea.api, 'GET failed: network', path: '/app/me');
      expect(d.entries, hasLength(1));
      expect(d.entries.single.count, 3);

      // Different path = different event; and after 60 s of quiet a new line.
      d.record(DiagArea.api, 'GET failed: network', path: '/app/posts');
      now = now.add(const Duration(seconds: 61));
      d.record(DiagArea.api, 'GET failed: network', path: '/app/me');
      expect(d.entries, hasLength(3));
    });

    test('record() scrubs message and path', () {
      final d = Diagnostics(now: clock)
        ..record(
          DiagArea.auth,
          'failed for jo@example.com with Bearer tok123',
          path: '/x?email=jo@example.com',
        );
      final line = d.entries.single;
      expect(line.message, isNot(contains('example.com')));
      expect(line.message, isNot(contains('tok123')));
      expect(line.path, '/x');
    });

    test('a corrupt file is discarded silently', () async {
      final storage = _MemoryStorage('{not json');
      final d = Diagnostics(storage: storage, now: clock);
      await d.load();
      expect(d.entries, isEmpty);
      expect(storage.deleted, isTrue);
      d.record(DiagArea.ui, 'still works');
      expect(d.entries, hasLength(1));
      d.dispose();
    });

    test('a file with a bad entry is discarded as a whole', () async {
      final storage = _MemoryStorage(
        jsonEncode([
          {'t': 'nope', 'lv': 'info', 'a': 'ui', 'm': 'x'},
        ]),
      );
      final d = Diagnostics(storage: storage, now: clock);
      await d.load();
      expect(d.entries, isEmpty);
    });

    test('saved entries load before ones recorded meanwhile', () async {
      final first = _MemoryStorage();
      final a = Diagnostics(storage: first, now: clock, debounce: Duration.zero)
        ..record(DiagArea.startup, 'old line');
      await a.flush();

      final b = Diagnostics(storage: first, now: clock)
        ..record(DiagArea.ui, 'new line');
      await b.load();
      expect(b.entries.map((e) => e.message), ['old line', 'new line']);
      b.dispose();
    });

    test('writes are debounced into one', () async {
      final storage = _MemoryStorage();
      final d = Diagnostics(
        storage: storage,
        now: clock,
        debounce: const Duration(milliseconds: 40),
      );
      for (var i = 0; i < 10; i++) {
        d.record(DiagArea.ui, 'event $i');
      }
      expect(storage.writes, 0);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(storage.writes, 1);
      expect(jsonDecode(storage.contents!) as List, hasLength(10));
      d.dispose();
    });

    test('clear() empties the log and the file', () async {
      final storage = _MemoryStorage();
      final d = Diagnostics(
        storage: storage,
        now: clock,
        debounce: Duration.zero,
      )..record(DiagArea.ui, 'x');
      await d.flush();
      d.clear();
      expect(d.entries, isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(storage.deleted, isTrue);
    });
  });

  group('report', () {
    test('has the header facts and entries newest first, with no secrets', () {
      final d = Diagnostics(now: clock)
        ..record(DiagArea.startup, 'cold start, version 1.0.0+2');
      now = now.add(const Duration(minutes: 1));
      d.record(
        DiagArea.api,
        'GET failed: server error for jo@example.com',
        level: DiagLevel.error,
        status: 500,
        path: '/app/me?token=abc',
      );
      final text = d.report(_info);

      expect(text, contains('App version: 1.0.0 (2)'));
      expect(text, contains('Database schema: 9'));
      expect(text, contains('Signed in: yes'));
      expect(text, contains('Active club: 1'));
      expect(
        text.indexOf('GET failed'),
        lessThan(text.indexOf('cold start')),
        reason: 'newest first',
      );
      expect(text, contains('/app/me -> 500'));
      expect(text, isNot(contains('example.com')));
      expect(text, isNot(contains('token=abc')));
    });
  });
}
