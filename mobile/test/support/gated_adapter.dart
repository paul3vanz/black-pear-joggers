import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fake_api.dart';

/// A [FakeAdapter] that can hold a request until the test releases it, to
/// check what a screen looks like while a save is in flight (and what a second
/// tap does). Add `gates['PUT /path'] = Completer()` and call `complete()`.
/// TS equivalent: a msw handler that awaits a promise you resolve later.
class GatedAdapter extends FakeAdapter {
  GatedAdapter(super.routes);

  /// Requests keyed like the routes ("PUT /app/...") wait for their completer.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final gate = gates['${options.method} ${options.path}'];
    if (gate != null) await gate.future;
    return super.fetch(options, requestStream, cancelFuture);
  }
}
