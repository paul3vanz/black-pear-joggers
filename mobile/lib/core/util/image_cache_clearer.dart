import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Empties the on-disk cache of downloaded images (member photos, series
/// images). A provider so tests don't touch the platform channels, same idea as
/// `urlOpener`.
final imageCacheClearerProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => DefaultCacheManager().emptyCache(),
);
