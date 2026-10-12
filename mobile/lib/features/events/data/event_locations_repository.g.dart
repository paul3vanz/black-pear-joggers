// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_locations_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventLocationsRepository)
final eventLocationsRepositoryProvider = EventLocationsRepositoryProvider._();

final class EventLocationsRepositoryProvider
    extends
        $FunctionalProvider<
          EventLocationsRepository,
          EventLocationsRepository,
          EventLocationsRepository
        >
    with $Provider<EventLocationsRepository> {
  EventLocationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventLocationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventLocationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventLocationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventLocationsRepository create(Ref ref) {
    return eventLocationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventLocationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventLocationsRepository>(value),
    );
  }
}

String _$eventLocationsRepositoryHash() =>
    r'fb612133c0ea00742e4257e253f3fc61d6067061';
