import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/club_config.dart';
import '../../../core/config/env.dart';

/// Landing screen when nobody is signed in. The router sends users here and, once an
/// account exists, redirects away automatically, so this screen never navigates itself.
///
/// `ConsumerStatefulWidget` is a stateful widget that also has a `ref` for reading
/// providers; `setState` is the equivalent of a `useState` setter.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _tokenController = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Technical detail (error type + code) shown under the friendly message, so a tester
  /// can screenshot it. Hide it once sign-in is proven.
  String? _detail;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _detail = null;
    });
    try {
      await action();
    } on LoginCancelledException {
      // User backed out of the browser: nothing to report.
    } on Object catch (e) {
      debugPrint('Sign-in failed: $e');
      if (mounted) {
        setState(() {
          _error = _describe(e);
          _detail = _technical(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _technical(Object e) {
    final text = '${e.runtimeType}: $e';
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }

  String _describe(Object e) => switch (e) {
    AuthNotConfiguredException() => "Sign-in isn't set up in this build yet.",
    FormatException(:final message) => message,
    ApiException(:final message) => message,
    _ => 'Something went wrong signing in. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubConfigProvider);
    final theme = Theme.of(context);
    final controller = ref.read(accountsControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    club.logoAsset,
                    height: 120,
                    semanticLabel: club.name,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    club.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to see your membership and club updates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (!Env.isAuth0Configured)
                    const _Notice(
                      icon: Icons.construction,
                      text:
                          "Sign-in isn't available in this build yet. "
                          "Auth0 hasn't been configured for the app.",
                    )
                  else
                    FilledButton(
                      onPressed: _busy ? null : () => _run(controller.signIn),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    if (_detail != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        _detail!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                  // kDebugMode is a compile-time constant, so this block is removed
                  // from release builds entirely.
                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    _DeveloperSignIn(
                      controller: _tokenController,
                      busy: _busy,
                      onSubmit: () => _run(
                        () => controller.signInWithAccessToken(
                          _tokenController.text,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Debug builds only: paste an access token copied from the website
/// (browser devtools, Application, Local Storage, `bpj.token`).
class _DeveloperSignIn extends StatelessWidget {
  const _DeveloperSignIn({
    required this.controller,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Developer: sign in with access token'),
      leading: const Icon(Icons.bug_report_outlined),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Access token (JWT)',
            hintText: 'eyJhbGciOi...',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: busy ? null : onSubmit,
          child: const Text('Use this token'),
        ),
      ],
    );
  }
}
