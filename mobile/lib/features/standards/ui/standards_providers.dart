import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/data/small_kv_store.dart';
import '../../groups/ui/groups_providers.dart';
import '../data/standards_repository.dart';

/// Live cached standards for a club (null until the first refresh succeeds).
/// Hand-written because riverpod_generator can't name Drift's generated types.
final standardsProvider = StreamProvider.family<CachedStandards?, int>(
  (ref, clubId) => ref.watch(standardsRepositoryProvider).watch(clubId),
);

/// Whether the standards screen shows paces (true) or times (false), kept on
/// the device (D91). A `Notifier` is a tiny store: `state` is the value,
/// `build` its first value, and methods change it (like `useState` that lives
/// outside the widget). The saved value arrives a moment after the first frame.
final standardsShowPaceProvider =
    NotifierProvider.autoDispose<StandardsShowPaceNotifier, bool>(
      StandardsShowPaceNotifier.new,
    );

class StandardsShowPaceNotifier extends Notifier<bool> {
  bool _touched = false;

  @override
  bool build() {
    unawaited(_load(ref.watch(smallKvStoreProvider)));
    return false;
  }

  Future<void> _load(SmallKvStore store) async {
    final saved = await store.get(SmallKvStore.standardsShowPaceKey);
    // A tap that beat the read wins over the saved value.
    if (ref.mounted && !_touched && saved == '1') state = true;
  }

  void set(bool showPace) {
    _touched = true;
    state = showPace;
    unawaited(
      ref
          .read(smallKvStoreProvider)
          .set(SmallKvStore.standardsShowPaceKey, showPace ? '1' : '0'),
    );
  }
}
