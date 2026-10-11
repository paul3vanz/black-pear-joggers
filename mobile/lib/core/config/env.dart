import 'package:flutter/foundation.dart';

/// Build-time configuration, injected with `--dart-define-from-file=config/<env>.json`.
///
/// React/TS equivalent: `process.env.NEXT_PUBLIC_*` / `import.meta.env`. The values are
/// baked in at compile time (`const`), so there is no runtime lookup and nothing secret
/// belongs here: the Auth0 client id and audience are public.
///
/// If you run without `--dart-define-from-file` every value falls back to the
/// defaults below (dev API, empty Auth0 client id).
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const auth0Domain = String.fromEnvironment(
    'AUTH0_DOMAIN',
    defaultValue: 'blackpearjoggers.us.auth0.com',
  );

  /// Client id of the Auth0 *Native* application. Empty until that app exists.
  static const auth0ClientId = String.fromEnvironment('AUTH0_CLIENT_ID');

  static const auth0Audience = String.fromEnvironment(
    'AUTH0_AUDIENCE',
    defaultValue: 'https://bpj.org.uk',
  );

  /// Custom URL scheme for the Universal Login redirect. Must match the Android
  /// `auth0Scheme` manifest placeholder and the iOS bundle identifier.
  static const auth0Scheme = String.fromEnvironment(
    'AUTH0_SCHEME',
    defaultValue: 'uk.org.bpj.app',
  );

  /// The club this build is for (server `clubs.id`).
  static const clubId = int.fromEnvironment('CLUB_ID', defaultValue: 1);

  /// False until the Auth0 Native app has been created and its client id added to
  /// `config/*.json`. The sign-in screen shows a friendly message in that case.
  static bool get isAuth0Configured =>
      auth0Domain.isNotEmpty && auth0ClientId.isNotEmpty;

  // Firebase (push). Public identifiers copied from the Firebase console; see
  // docs/setup.md. Empty means push is off and the rest of the app works as normal.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  /// True when every Firebase value needed for the current platform is set.
  static bool get isFirebaseConfigured => firebaseConfiguredFor(
    isIos: defaultTargetPlatform == TargetPlatform.iOS,
    apiKey: firebaseApiKey,
    projectId: firebaseProjectId,
    senderId: firebaseMessagingSenderId,
    androidAppId: firebaseAndroidAppId,
    iosAppId: firebaseIosAppId,
  );
}

/// Pure so it can be unit-tested without compile-time defines.
bool firebaseConfiguredFor({
  required bool isIos,
  required String apiKey,
  required String projectId,
  required String senderId,
  required String androidAppId,
  required String iosAppId,
}) =>
    apiKey.isNotEmpty &&
    projectId.isNotEmpty &&
    senderId.isNotEmpty &&
    (isIos ? iosAppId : androidAppId).isNotEmpty;
