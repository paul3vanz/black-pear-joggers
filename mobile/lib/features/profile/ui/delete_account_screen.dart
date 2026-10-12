import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/image_cache_clearer.dart';
import '../data/account_repository.dart';

/// Full-screen "Delete my account" confirmation (D72). Explains what goes and what
/// stays, and only enables the red button once the member has typed `DELETE`.
///
/// Nothing here is optimistic: local data and credentials are only removed after
/// the server answers 204.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Exact, case-sensitive match (so "delete" or "DELETE " do not count).
  bool get _confirmed => _controller.text == deleteConfirmWord;

  Future<void> _delete() async {
    if (_busy || !_confirmed) return; // a second tap while running is ignored
    // Grab everything we need from `ref` NOW. Once local data is cleared the router
    // redirects and this screen is disposed, after which `ref.read` would throw.
    final repo = ref.read(accountRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final db = ref.read(appDatabaseProvider);
    final accounts = ref.read(accountsControllerProvider.notifier);
    final clearImageCache = ref.read(imageCacheClearerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await repo.deleteAccount();
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      final api = ApiException.from(e);
      setState(() {
        _busy = false;
        _error = api.isNetworkError
            ? 'You need a connection to delete your account.'
            : api.code == 'last_admin'
            ? api.message
            : "Something went wrong and your account wasn't deleted. "
                  '${api.message} Please try again.';
      });
      return;
    }

    // The server has deleted everything it holds. Now the local side.
    // 1. Empty this account's database while its connection is still open. We
    //    empty the rows rather than delete the file: removing a SQLite file under
    //    an open connection is unsafe, and an empty file holds nothing personal.
    //    (It also tells the router the account is unlinked, which is now true.)
    try {
      await db.clearAll();
      await clearImageCache();
    } on Object catch (e) {
      // Best effort: the account is already gone on the server, so never block
      // the sign-out on a cleanup failure.
      debugPrint('Local cleanup after account deletion failed: $e');
    }
    // 2. Exactly the normal sign-out: push token, credentials, Auth0 session when
    //    it was the last account. The router then moves to the next signed-in
    //    account or to the sign-in screen.
    if (sub != null) await accounts.remove(sub);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyLarge;

    // PopScope(canPop: false) blocks Back/close while the request is in flight.
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Delete my account')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'This cannot be undone.',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text('What will be deleted', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              const _Bullets([
                'Your profile card, photo and goals',
                'Your chat messages',
                'Your run sign-ups and leader sign-ups',
                'Your notification settings',
                'Your link to your club membership in this app',
              ]),
              const SizedBox(height: 16),
              Text(
                'What will not be deleted',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const _Bullets([
                'Your Black Pear Joggers website login',
                'Your club membership',
              ]),
              const SizedBox(height: 8),
              Text(
                'To remove those as well, please contact the club.',
                style: body,
              ),
              const SizedBox(height: 24),
              Text('To confirm, type $deleteConfirmWord below.', style: body),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('confirm-field'),
                controller: _controller,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type $deleteConfirmWord',
                ),
                // Rebuild so the button reflects the text, like controlled input state.
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const ValueKey('delete-error'),
                  style: TextStyle(color: scheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('delete-confirm'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _confirmed && !_busy ? _delete : null,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(_error == null ? 'Delete my account' : 'Try again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(item)),
            ],
          ),
        ),
    ],
  );
}
