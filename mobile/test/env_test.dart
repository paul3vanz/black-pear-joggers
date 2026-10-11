import 'package:bpj/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool configured({
    bool isIos = false,
    String apiKey = 'k',
    String projectId = 'p',
    String senderId = 's',
    String androidAppId = 'a',
    String iosAppId = 'i',
  }) => firebaseConfiguredFor(
    isIos: isIos,
    apiKey: apiKey,
    projectId: projectId,
    senderId: senderId,
    androidAppId: androidAppId,
    iosAppId: iosAppId,
  );

  test('firebase is configured only when the platform values are all set', () {
    expect(configured(), isTrue);
    expect(configured(apiKey: ''), isFalse);
    expect(configured(projectId: ''), isFalse);
    expect(configured(senderId: ''), isFalse);
    // Only the current platform's app id is required.
    expect(configured(androidAppId: '', iosAppId: 'i'), isFalse);
    expect(configured(isIos: true, androidAppId: ''), isTrue);
    expect(configured(isIos: true, iosAppId: ''), isFalse);
  });

  test('unconfigured by default (empty config)', () {
    expect(Env.isFirebaseConfigured, isFalse);
  });
}
