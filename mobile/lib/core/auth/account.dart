/// A signed-in person on this device, identified by their Auth0 `sub`
/// (e.g. `google-oauth2|1234`). Several can be stored at once.
///
/// Plain Dart class with hand-written JSON: it is tiny, so we skip codegen here.
class Account {
  const Account({required this.sub, this.name, this.email, this.pictureUrl});

  final String sub;
  final String? name;
  final String? email;
  final String? pictureUrl;

  /// Best label to show in an account switcher.
  String get displayName => name ?? email ?? sub;

  Map<String, Object?> toJson() => {
    'sub': sub,
    'name': name,
    'email': email,
    'pictureUrl': pictureUrl,
  };

  factory Account.fromJson(Map<String, Object?> json) => Account(
    sub: json['sub']! as String,
    name: json['name'] as String?,
    email: json['email'] as String?,
    pictureUrl: json['pictureUrl'] as String?,
  );
}

/// Tokens for one account. Kept in secure storage under `cred_<sub>`.
class StoredCredentials {
  const StoredCredentials({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? idToken;

  /// True if the access token is expired or will expire within [margin].
  bool isExpiringWithin(Duration margin, {DateTime? now}) =>
      !expiresAt.isAfter((now ?? DateTime.now()).add(margin));

  StoredCredentials copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? idToken,
  }) => StoredCredentials(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    idToken: idToken ?? this.idToken,
  );

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'idToken': idToken,
  };

  factory StoredCredentials.fromJson(Map<String, Object?> json) =>
      StoredCredentials(
        accessToken: json['accessToken']! as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: DateTime.parse(json['expiresAt']! as String),
        idToken: json['idToken'] as String?,
      );
}
