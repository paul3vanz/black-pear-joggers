import 'dart:async';

import 'package:auth0_flutter/auth0_flutter.dart' as auth0_sdk;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import 'account.dart';
import 'account_store.dart';
import 'jwt.dart';

part 'auth_service.g.dart';

/// Thrown when an account's session can't be renewed (no refresh token, or Auth0
/// rejected it). The UI should send the user back through sign-in.
class SessionExpiredException implements Exception {
  const SessionExpiredException(this.sub);
  final String sub;

  @override
  String toString() => 'SessionExpiredException(sub: $sub)';
}

/// Thrown when renewing the access token failed for a reason that does NOT mean
/// the session is dead: no network, Auth0 5xx or 429, or an unexpected local error
/// (a platform exception, say). The caller shows a retryable error and keeps the
/// account. [isNetworkError] says whether to word it as "offline".
class AuthRenewalException implements Exception {
  const AuthRenewalException({required this.isNetworkError, this.cause});

  final bool isNetworkError;
  final Object? cause;

  @override
  String toString() =>
      'AuthRenewalException(network: $isNetworkError, cause: $cause)';
}

/// Thrown when sign-in is attempted before the Auth0 Native app id is configured.
class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
  @override
  String toString() => 'Auth0 is not configured (AUTH0_CLIENT_ID is empty).';
}

/// Thrown when the user closes the browser sheet without signing in.
class LoginCancelledException implements Exception {
  const LoginCancelledException();
}

/// Talks to Auth0 and keeps [AccountStore] up to date. The UI never touches tokens
/// directly: the API client asks [getValidAccessToken] for one per request.
class AuthService {
  /// [isConfigured] defaults to [Env.isAuth0Configured]; tests override it.
  AuthService(this._store, {this._auth0, bool? isConfigured})
    : _isConfigured = isConfigured ?? Env.isAuth0Configured;

  final AccountStore _store;
  auth0_sdk.Auth0? _auth0;
  final bool _isConfigured;

  /// Renewals in flight, per account. Auth0 refresh tokens rotate, so two parallel
  /// renewals would invalidate each other: share one future instead
  /// (like de-duplicating concurrent fetches in React Query).
  final Map<String, Future<StoredCredentials>> _renewals = {};

  static const _scopes = {'openid', 'profile', 'email', 'offline_access'};
  static const _renewMargin = Duration(seconds: 60);
  static const _renewTimeout = Duration(seconds: 30);

  auth0_sdk.Auth0 get _client =>
      _auth0 ??= auth0_sdk.Auth0(Env.auth0Domain, Env.auth0ClientId);

  /// Opens Universal Login in the system browser and stores the resulting account.
  /// Pass [addAccount] to force the login form (`prompt=login`) so the browser doesn't
  /// silently reuse the previous account's session.
  Future<Account> login({bool addAccount = false}) async {
    if (!Env.isAuth0Configured) throw const AuthNotConfiguredException();

    final auth0_sdk.Credentials credentials;
    try {
      credentials = await _client
          // useCredentialsManager: false → we keep tokens ourselves, per account.
          .webAuthentication(
            scheme: Env.auth0Scheme,
            useCredentialsManager: false,
          )
          .login(
            audience: Env.auth0Audience,
            scopes: _scopes,
            parameters: addAccount ? {'prompt': 'login'} : {},
          );
    } on auth0_sdk.WebAuthenticationException catch (e) {
      if (e.isUserCancelledException) throw const LoginCancelledException();
      rethrow;
    }

    final user = credentials.user;
    final account = Account(
      sub: user.sub,
      name: user.name ?? user.nickname,
      email: user.email,
      pictureUrl: user.pictureUrl?.toString(),
    );
    await _store.upsertAccount(account);
    await _store.writeCredentials(
      account.sub,
      StoredCredentials(
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        expiresAt: credentials.expiresAt,
        idToken: credentials.idToken,
      ),
    );
    await _store.writeActiveSub(account.sub);
    return account;
  }

  /// DEBUG BUILDS ONLY. Stores a pasted access token (e.g. from the website's
  /// `localStorage['bpj.token']`) as an account with no refresh token, so the app can be
  /// exercised before the Auth0 Native app exists. The JWT isn't verified here.
  Future<Account> signInWithAccessToken(String token) async {
    if (!kDebugMode) {
      throw StateError(
        'signInWithAccessToken is only available in debug builds',
      );
    }
    final payload = decodeJwtPayload(token);
    final sub = payload['sub'] as String?;
    final exp = payload['exp'];
    if (sub == null) throw const FormatException('Token has no "sub" claim');

    final account = Account(
      sub: sub,
      name: payload['name'] as String?,
      email: payload['email'] as String?,
      pictureUrl: payload['picture'] as String?,
    );
    await _store.upsertAccount(account);
    await _store.writeCredentials(
      sub,
      StoredCredentials(
        accessToken: token.trim(),
        // Tokens without `exp` are treated as valid for an hour.
        expiresAt: exp is num
            ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
            : DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await _store.writeActiveSub(sub);
    return account;
  }

  /// Returns an access token for [sub], renewing it first if it expires within 60s.
  /// With [forceRenew] it always renews (used after a 401).
  /// Throws [SessionExpiredException] if that's impossible.
  Future<String> getValidAccessToken(
    String sub, {
    bool forceRenew = false,
  }) async {
    final stored = await _store.readCredentials(sub);
    if (stored == null) throw SessionExpiredException(sub);

    if (!forceRenew && !stored.isExpiringWithin(_renewMargin)) {
      return stored.accessToken;
    }
    final renewed = await _renewShared(sub, stored);
    return renewed.accessToken;
  }

  /// One renewal per account at a time: callers that arrive while it runs share
  /// its result (or its failure).
  ///
  /// The entry is removed in a separate `then`, NOT with
  /// `_renew(..).whenComplete(() => _renewals.remove(sub))`: that callback
  /// returns the map entry, which is the very future `whenComplete` is about to
  /// complete, so it waited for itself forever. Every request that needed a
  /// renewal then hung before reaching the network, with no error to route the
  /// user to sign-in (D103).
  Future<StoredCredentials> _renewShared(String sub, StoredCredentials stored) {
    final running = _renewals[sub];
    if (running != null) return running;
    final renewal = _renew(sub, stored);
    _renewals[sub] = renewal;
    // Block bodies on purpose: an arrow would return the removed future, which
    // would then be awaited (and rethrow its error) by this derived future.
    renewal.then<void>(
      (_) {
        _renewals.remove(sub);
      },
      onError: (Object _) {
        _renewals.remove(sub);
      },
    );
    return renewal;
  }

  Future<StoredCredentials> _renew(String sub, StoredCredentials old) async {
    final refreshToken = old.refreshToken;
    if (refreshToken == null || !_isConfigured) {
      throw SessionExpiredException(sub);
    }
    final StoredCredentials updated;
    try {
      final fresh = await _client.api
          .renewCredentials(refreshToken: refreshToken)
          // A platform call that never answers must not hang every request.
          .timeout(_renewTimeout);
      updated = StoredCredentials(
        accessToken: fresh.accessToken,
        // Rotation may or may not return a new refresh token: keep the old one if not.
        refreshToken: fresh.refreshToken ?? refreshToken,
        expiresAt: fresh.expiresAt,
        idToken: fresh.idToken,
      );
    } on auth0_sdk.ApiException catch (e) {
      // Network trouble, a 429, an Auth0 outage or a failure with no HTTP
      // status at all (statusCode 0: it never got an answer) isn't a dead
      // session: the caller shows a retryable error and the account stays (D103).
      // Only an answer in the 4xx range (invalid_grant and friends) ends it.
      if (e.isNetworkError ||
          e.statusCode == 0 ||
          e.statusCode >= 500 ||
          e.statusCode == 429) {
        throw AuthRenewalException(isNetworkError: e.isNetworkError, cause: e);
      }
      throw SessionExpiredException(sub);
    } on TimeoutException catch (e) {
      throw AuthRenewalException(isNetworkError: true, cause: e);
    } on Object catch (e) {
      // Anything else (a platform exception, a malformed reply) is a local
      // failure, not proof that the refresh token is bad.
      throw AuthRenewalException(isNetworkError: false, cause: e);
    }
    try {
      await _store.writeCredentials(sub, updated);
    } on Object {
      // The new token is good for this session even if it can't be saved.
    }
    return updated;
  }

  /// Signs [sub] out of this device. The Auth0 browser session is only cleared when it
  /// was the last account, so signing out one account doesn't log the others out of SSO.
  Future<void> logout(String sub) async {
    await _store.removeAccount(sub);
    final remaining = await _store.readAccounts();
    if (remaining.isEmpty && _isConfigured) {
      try {
        await _client
            .webAuthentication(
              scheme: Env.auth0Scheme,
              useCredentialsManager: false,
            )
            .logout();
      } on auth0_sdk.WebAuthenticationException {
        // User closed the browser or no network: local sign-out has already happened.
      }
    }
  }
}

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) =>
    AuthService(ref.watch(accountStoreProvider));
