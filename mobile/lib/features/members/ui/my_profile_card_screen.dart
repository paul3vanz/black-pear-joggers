import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/member_dtos.dart';
import '../data/member_profile_repository.dart';
import '../logic/profile_photo.dart';
import 'member_avatar.dart';
import 'member_providers.dart';

/// Where a profile photo comes from.
enum PhotoSource { gallery, camera }

/// Lets the member pick or take a photo and returns its bytes (null = cancelled).
/// A provider so widget tests can skip the platform channel (like `urlOpener`).
typedef PhotoPicker = Future<Uint8List?> Function(PhotoSource source);

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => (source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return file?.readAsBytes();
  },
);

/// Crops/resizes/re-encodes a picked photo (see [processProfilePhoto]). The
/// default runs it on a background isolate so a 12 MP photo doesn't freeze the
/// UI; tests replace it with a direct call.
final photoProcessorProvider = Provider<Future<Uint8List> Function(Uint8List)>(
  (ref) =>
      (bytes) => compute(processProfilePhoto, bytes),
);

/// "My profile card" (`/profile/card`): photo, bio, goals and whether goals are
/// shared (D59). Reads work offline from the cache; every write needs a
/// connection. The photo is processed on the phone before upload (D60).
class MyProfileCardScreen extends ConsumerStatefulWidget {
  const MyProfileCardScreen({super.key});

  @override
  ConsumerState<MyProfileCardScreen> createState() =>
      _MyProfileCardScreenState();
}

class _MyProfileCardScreenState extends ConsumerState<MyProfileCardScreen> {
  final _bio = TextEditingController();
  final _goals = TextEditingController();
  bool _goalsVisible = false;

  // What the server last had; "changed" means different from these.
  bool _ready = false;
  String _baseBio = '';
  String _baseGoals = '';
  bool _baseVisible = false;

  bool _busy = false;
  bool _fetching = true;
  DateTime? _staleSince;
  String? _bioError;
  String? _goalsError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _bio.dispose();
    _goals.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _bio.text.trim() != _baseBio ||
      _goals.text.trim() != _baseGoals ||
      _goalsVisible != _baseVisible;

  /// Takes the server's texts as the new baseline. Unless [force], text the
  /// member has already started editing is kept.
  void _applyCard(MyCard card, {bool force = false}) {
    final keepEdits = _ready && _dirty && !force;
    _baseBio = card.bio ?? '';
    _baseGoals = card.goals ?? '';
    _baseVisible = card.goalsVisible;
    if (!keepEdits) {
      _bio.text = _baseBio;
      _goals.text = _baseGoals;
      _goalsVisible = _baseVisible;
    }
    _ready = true;
  }

  Future<void> _load() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(memberProfileRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (mounted) setState(() => _fetching = true);
    DateTime? staleSince;
    MyCard? card;
    try {
      final result = await repo.fetchMine(clubId);
      card = result.value;
      if (result.fromCache) staleSince = result.fetchedAt;
    } on MemberOfflineException {
      // Nothing cached and no connection: the offline message shows.
    } on ApiException catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (mounted) _snack(memberErrorMessage(e));
    }
    if (!mounted) return;
    setState(() {
      if (card != null) _applyCard(card);
      _fetching = false;
      _staleSince = staleSince;
    });
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Runs a write: shows progress, maps failures to messages / field errors.
  Future<void> _write(Future<void> Function(int clubId) action) async {
    final clubId = ref.read(activeClubIdProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    setState(() => _busy = true);
    try {
      await action(clubId);
    } on ApiException catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      setState(() {
        _bioError = e.fieldErrors['bio'];
        _goalsError = e.fieldErrors['goals'];
      });
      final other =
          e.fieldErrors['photo'] ??
          (e.fieldErrors.keys.any((k) => k == 'bio' || k == 'goals')
              ? null
              : memberErrorMessage(e));
      if (other != null) _snack(other);
    } on Object {
      if (mounted) _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _write((clubId) async {
    final bio = _bio.text.trim();
    final goals = _goals.text.trim();
    final card = await ref
        .read(memberProfileRepositoryProvider)
        .saveMine(
          clubId,
          // Only what changed; an empty string clears a field.
          bio: bio != _baseBio ? bio : null,
          goals: goals != _baseGoals ? goals : null,
          goalsVisible: _goalsVisible != _baseVisible ? _goalsVisible : null,
        );
    if (!mounted) return;
    setState(() {
      _bioError = null;
      _goalsError = null;
      _applyCard(card, force: true);
    });
    _snack('Saved');
  });

  Future<void> _pickPhoto(PhotoSource source) async {
    final bytes = await _pick(source);
    if (bytes == null || !mounted) return;
    setState(() => _busy = true);
    Uint8List jpeg;
    try {
      jpeg = await ref.read(photoProcessorProvider)(bytes);
    } on ProfilePhotoException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(e.message);
      }
      return;
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        _snack("That photo couldn't be read. Try another one.");
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final use = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use this photo?'),
        content: ClipOval(
          child: Image.memory(
            jpeg,
            key: const ValueKey('photo-preview'),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use photo'),
          ),
        ],
      ),
    );
    if (use != true || !mounted) return;
    await _write((clubId) async {
      await ref.read(memberProfileRepositoryProvider).uploadPhoto(clubId, jpeg);
      if (mounted) _snack('Photo saved');
    });
  }

  Future<Uint8List?> _pick(PhotoSource source) async {
    try {
      return await ref.read(photoPickerProvider)(source);
    } on PlatformException {
      if (mounted) {
        _snack(
          source == PhotoSource.camera
              ? "Couldn't open the camera. Check the app's camera permission "
                    'in Settings.'
              : "Couldn't open your photos. Check the app's photos permission "
                    'in Settings.',
        );
      }
      return null;
    }
  }

  Future<void> _removePhoto() => _write((clubId) async {
    await ref.read(memberProfileRepositoryProvider).removePhoto(clubId);
    if (mounted) _snack('Photo removed');
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = ref.watch(myCardProvider).value;
    final membership = ref.watch(activeMembershipProvider);
    final myId = ref.watch(ownMemberIdProvider);
    final name = [
      membership?.firstName,
      if ((membership?.lastName ?? '').isNotEmpty)
        '${membership!.lastName![0]}.',
    ].whereType<String>().join(' ');
    final photoPath = card?.photoPath;
    // The cached card can arrive a moment after the first build.
    if (!_ready && card != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_ready) setState(() => _applyCard(card));
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My profile card')),
      body: SafeArea(
        child: !_ready
            ? _fetching
                  ? const Center(child: CircularProgressIndicator())
                  : _OfflineEmpty(onRetry: _load)
            : ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_staleSince != null) ...[
                    OfflineBanner(
                      'Offline: showing your last saved card '
                      '(updated ${relativeTime(_staleSince!)}). You need a '
                      'connection to save changes.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Your photo and bio are visible to other BPJ members in '
                    'the app. Goals are private unless you share them.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      AvatarCircle(
                        name: name,
                        photoUrl: ref.watch(memberPhotoUrlProvider)(photoPath),
                        size: 96,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _pickPhoto(PhotoSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose photo'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _pickPhoto(PhotoSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Take photo'),
                            ),
                            if (photoPath != null)
                              TextButton.icon(
                                onPressed: _busy ? null : _removePhoto,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove photo'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('bio-field'),
                    controller: _bio,
                    maxLength: maxBioLength,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'A few words about you',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      errorText: _bioError,
                    ),
                    onChanged: (_) => setState(() => _bioError = null),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('goals-field'),
                    controller: _goals,
                    maxLength: maxGoalsLength,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Your running goals',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      errorText: _goalsError,
                    ),
                    onChanged: (_) => setState(() => _goalsError = null),
                  ),
                  CheckboxListTile(
                    key: const ValueKey('share-goals'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _goalsVisible,
                    onChanged: (v) =>
                        setState(() => _goalsVisible = v ?? false),
                    title: const Text('Share my goals with other members'),
                    subtitle: const Text(
                      'Only you can see your goals unless you tick this.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _dirty && !_busy ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: myId == null
                        ? null
                        : () => context.push('/members/$myId'),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('See how others see me'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OfflineEmpty extends StatelessWidget {
  const _OfflineEmpty({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 16),
          const Text(
            "You're offline. Connect to the internet to set up your profile "
            'card.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
