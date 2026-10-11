import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_exception.dart';
import 'accounts_controller.dart';

part 'session_expiry.g.dart';

/// Key for the app's root `ScaffoldMessenger`, so code outside the widget tree
/// (like the session-expiry handler) can show a SnackBar. In React terms: a ref to
/// a toast container that any module can reach.
@Riverpod(keepAlive: true)
GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey(Ref ref) =>
    GlobalKey<ScaffoldMessengerState>();

/// Call from any `catch`. If [error] is a `session_expired` [ApiException], drops
/// the dead account for [sub] (the router then moves to the next account or the
/// sign-in screen), tells the user, and returns true. Otherwise returns false and
/// does nothing, so callers go on to handle the error themselves.
typedef SessionExpiryHandler = Future<bool> Function(String sub, Object error);

@Riverpod(keepAlive: true)
SessionExpiryHandler sessionExpiryHandler(Ref ref) => (sub, error) async {
  if (!ApiException.from(error).isSessionExpired) return false;
  await ref.read(accountsControllerProvider.notifier).sessionExpired(sub);
  ref
      .read(scaffoldMessengerKeyProvider)
      .currentState
      ?.showSnackBar(
        const SnackBar(
          content: Text('Your session expired — please sign in again'),
        ),
      );
  return true;
};
