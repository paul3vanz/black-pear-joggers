import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/auth_service.dart';

/// Shows the account switcher as a bottom sheet: every signed-in account (the active
/// one ticked), "Add another account", and in debug builds a paste-a-token option.
/// `showModalBottomSheet` is the Flutter version of opening a modal/drawer imperatively.
Future<void> showAccountSwitcher(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const AccountSwitcherSheet(),
    );

class AccountSwitcherSheet extends ConsumerWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsControllerProvider).value;
    final accounts = state?.accounts ?? const [];
    final controller = ref.read(accountsControllerProvider.notifier);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> addAccount() async {
      navigator.pop();
      try {
        await controller.signIn(addAccount: true);
      } on LoginCancelledException {
        // Closed the browser: nothing to report.
      } on Object catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e is AuthNotConfiguredException
                  ? "Sign-in isn't set up in this build yet."
                  : "Couldn't add the account. Please try again.",
            ),
          ),
        );
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final account in accounts)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    account.displayName.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(account.displayName),
                subtitle: account.email != null && account.name != null
                    ? Text(account.email!)
                    : null,
                trailing: account.sub == state?.activeSub
                    ? const Icon(Icons.check, semanticLabel: 'Active account')
                    : null,
                onTap: () async {
                  navigator.pop();
                  if (account.sub != state?.activeSub) {
                    await controller.switchTo(account.sub);
                  }
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Add another account'),
              onTap: addAccount,
            ),
            // kDebugMode is a compile-time constant: removed from release builds.
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Developer: add account with access token'),
                onTap: () async {
                  navigator.pop();
                  final token = await showDialog<String>(
                    context: navigator.context,
                    builder: (_) => const _PasteTokenDialog(),
                  );
                  if (token == null || token.trim().isEmpty) return;
                  try {
                    await controller.signInWithAccessToken(token);
                  } on Object catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e is FormatException ? e.message : 'Invalid token',
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PasteTokenDialog extends StatefulWidget {
  const _PasteTokenDialog();

  @override
  State<_PasteTokenDialog> createState() => _PasteTokenDialogState();
}

class _PasteTokenDialogState extends State<_PasteTokenDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Access token'),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(hintText: 'eyJhbGciOi...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Use token'),
        ),
      ],
    );
  }
}
