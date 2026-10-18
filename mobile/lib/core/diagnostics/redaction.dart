import 'package:flutter/services.dart';

/// Scrubbing for the diagnostics log (D100). Everything that is written to the
/// log goes through [redact] or [safePath] first, so a pasted report never holds a
/// token, an email address or a login id. React/TS equivalent: a `sanitize()` helper
/// you run over every log line before it leaves the module.
const redactedMark = '[redacted]';

final _patterns = <RegExp>[
  // `Authorization: Bearer abc...` (and the bare `Bearer abc...`).
  RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
  // A JWT: three base64url chunks, the first two starting `eyJ`.
  RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'),
  RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+'),
  // Auth0 user ids: `auth0|123`, `google-oauth2|123`.
  RegExp(r'[A-Za-z0-9-]+\|[A-Za-z0-9]+'),
  // Any other long opaque token (hex digests, refresh tokens).
  RegExp(r'[A-Za-z0-9_-]{32,}'),
];

const _maxMessage = 200;

/// Replaces anything token-, email- or login-id-shaped with `[redacted]`, flattens
/// newlines and caps the length.
String redact(String input) {
  var out = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final p in _patterns) {
    out = out.replaceAll(p, redactedMark);
  }
  return out.length > _maxMessage ? '${out.substring(0, _maxMessage)}…' : out;
}

final _uuid = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

/// A request path for the log: no query string, no fragment, record uuids
/// replaced by `:id` (they say nothing useful and are not ours to log).
String safePath(String path) {
  final cut = path.split(RegExp('[?#]')).first;
  return redact(cut.replaceAll(_uuid, ':id'));
}

/// Error types whose message is safe and useful (no user content in it).
const _messageSafeTypes = {
  'TypeError',
  'StateError',
  'FlutterError',
  'SqliteException',
  'DriftWrappedException',
  'MissingPluginException',
  'FileSystemException',
};

/// Error types that carry a short machine code (Auth0's and the app's own
/// `ApiException`), safe to log and the most useful part for support.
const _codeTypes = {
  'WebAuthenticationException',
  'CredentialsManagerException',
  'ApiException',
};

/// A short, safe description of anything thrown: the type, plus the message for
/// the few types whose messages never hold user content. A `FormatException`
/// message quotes the text it failed to parse, so it never gets through.
String describeError(Object error) {
  final type = error.runtimeType.toString();
  if (error is PlatformException) return redact('$type(${error.code})');
  if (_codeTypes.contains(type)) {
    // `dynamic` because these classes live in packages this file shouldn't import.
    try {
      final code = (error as dynamic).code;
      return redact(code is String ? '$type($code)' : type);
    } on NoSuchMethodError {
      return redact(type);
    }
  }
  if (!_messageSafeTypes.contains(type)) return redact(type);
  final firstLine = error.toString().split('\n').first;
  return redact('$type: $firstLine');
}
