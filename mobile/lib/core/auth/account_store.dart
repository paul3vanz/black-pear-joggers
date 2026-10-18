import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'account.dart';

part 'account_store.g.dart';

/// Persists every account on this device in the platform keystore
/// (Android Keystore / iOS Keychain). React/TS equivalent: a typed wrapper around
/// `localStorage`, except the values are encrypted and not readable by other apps.
///
/// Keys:
/// * `accounts`          JSON list of [Account]
/// * `cred_<sub>`        JSON [StoredCredentials] for that account
/// * `activeSub`         the account currently in use
/// * `club_<sub>`        that account's active club id
///
/// We deliberately don't use auth0_flutter's CredentialsManager: it holds a single user.
class AccountStore {
  AccountStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accountsKey = 'accounts';
  static const _activeSubKey = 'activeSub';
  static String _credKey(String sub) => 'cred_$sub';
  static String _clubKey(String sub) => 'club_$sub';

  /// What the Android plugin hands to a `read` after it hit an error and wiped
  /// the store (`resetOnError` defaults to true): the literal text arrives as if
  /// it were the stored value, and the Dart side doesn't filter it (D104).
  static const _resetSentinel = 'Data has been reset';

  /// Every read goes through here. Storage can fail to decrypt (Keystore key
  /// gone after a restore or an OS/OEM change, Samsung Knox quirks) and then
  /// throws a `PlatformException`, or hands back [_resetSentinel]. Neither may
  /// escape: an unreadable value is the same as a missing one, so the app falls
  /// back to the sign-in screen instead of failing every request (D104).
  Future<String?> _read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null || value.isEmpty || value == _resetSentinel) {
        return null;
      }
      return value;
    } on Object {
      return null;
    }
  }

  /// Best-effort delete of a value we found unusable.
  Future<void> _discard(String key) async {
    try {
      await _storage.delete(key: key);
    } on Object {
      // Nothing more we can do; the next write replaces the entry anyway.
    }
  }

  Future<List<Account>> readAccounts() async {
    final raw = await _read(_accountsKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<Object?>;
      final accounts = <Account>[];
      for (final item in list) {
        // One bad entry must not hide the others.
        try {
          accounts.add(
            Account.fromJson(Map<String, Object?>.from(item! as Map)),
          );
        } on Object {
          continue;
        }
      }
      return accounts;
    } on Object {
      // Not JSON, or not a list (FormatException, TypeError).
      await _discard(_accountsKey);
      return const [];
    }
  }

  Future<void> _writeAccounts(List<Account> accounts) => _storage.write(
    key: _accountsKey,
    value: jsonEncode([for (final a in accounts) a.toJson()]),
  );

  /// Adds the account, or replaces the details if the `sub` is already stored.
  Future<void> upsertAccount(Account account) async {
    final accounts = [...await readAccounts()];
    final i = accounts.indexWhere((a) => a.sub == account.sub);
    if (i >= 0) {
      accounts[i] = account;
    } else {
      accounts.add(account);
    }
    await _writeAccounts(accounts);
  }

  Future<void> removeAccount(String sub) async {
    final accounts = (await readAccounts()).where((a) => a.sub != sub).toList();
    await _writeAccounts(accounts);
    await _discard(_credKey(sub));
    await _discard(_clubKey(sub));
    if (await readActiveSub() == sub) {
      await writeActiveSub(accounts.isEmpty ? null : accounts.first.sub);
    }
  }

  Future<StoredCredentials?> readCredentials(String sub) async {
    final raw = await _read(_credKey(sub));
    if (raw == null) return null;
    try {
      return StoredCredentials.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      // Valid JSON of the wrong shape throws a TypeError, not a
      // FormatException: catching only the latter let it escape from every
      // request and fail the whole app silently. Drop the dead value.
      await _discard(_credKey(sub));
      return null;
    }
  }

  Future<void> writeCredentials(String sub, StoredCredentials credentials) =>
      _storage.write(
        key: _credKey(sub),
        value: jsonEncode(credentials.toJson()),
      );

  Future<void> deleteCredentials(String sub) => _discard(_credKey(sub));

  Future<String?> readActiveSub() => _read(_activeSubKey);

  Future<void> writeActiveSub(String? sub) => sub == null
      ? _storage.delete(key: _activeSubKey)
      : _storage.write(key: _activeSubKey, value: sub);

  Future<int?> readActiveClubId(String sub) async {
    final raw = await _read(_clubKey(sub));
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> writeActiveClubId(String sub, int clubId) =>
      _storage.write(key: _clubKey(sub), value: '$clubId');

  /// Small device-wide boolean flags (e.g. "we already asked for notification
  /// permission"). Stored under `flag_<name>`.
  Future<bool> readFlag(String name) async => await _read('flag_$name') == '1';

  Future<void> writeFlag(String name, {required bool value}) => value
      ? _storage.write(key: 'flag_$name', value: '1')
      : _storage.delete(key: 'flag_$name');
}

/// Riverpod provider ≈ a module-level singleton you can swap in tests
/// (`ProviderScope(overrides: [...])` is like wrapping a component in a test Context).
@Riverpod(keepAlive: true)
AccountStore accountStore(Ref ref) =>
    AccountStore(const FlutterSecureStorage());
