import 'dart:convert';

/// Decodes a JWT payload WITHOUT verifying the signature. Only used to read `sub`/`exp`
/// from a token pasted in debug builds; the API still verifies every token itself.
Map<String, Object?> decodeJwtPayload(String token) {
  final parts = token.trim().split('.');
  if (parts.length != 3) {
    throw const FormatException('Not a JWT (expected 3 dot-separated parts)');
  }
  final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  return Map<String, Object?>.from(jsonDecode(json) as Map);
}
