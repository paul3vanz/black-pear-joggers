import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/config/club_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/open_link.dart';
import '../data/membership_repository.dart';
import 'membership_providers.dart';

enum _Phase { form, found, notFound }

/// Link flow (`/link`): the member enters their England Athletics URN and date of
/// birth, the API checks them against the athletes table and links the login in one
/// call. Local widget state (`_phase`, `_busy`...) uses `setState`, the equivalent of
/// `useState`; the server work goes through [MembershipRepository].
class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({super.key});

  @override
  ConsumerState<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends ConsumerState<LinkScreen> {
  static final _dobFormat = DateFormat('d MMM yyyy');

  final _formKey = GlobalKey<FormState>();
  final _urnController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _dob;

  _Phase _phase = _Phase.form;
  bool _busy = false;
  String? _error;
  Membership? _found;

  @override
  void dispose() {
    _urnController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 40, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Date of birth',
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dobController.text = _dobFormat.format(picked);
    });
  }

  Future<void> _findMe() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(membershipRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final membership = await repo.link(
        clubId,
        urn: int.parse(_urnController.text.trim()),
        dob: _dob!,
      );
      if (!mounted) return;
      setState(() {
        _found = membership;
        _phase = _Phase.found;
      });
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      final api = ApiException.from(e);
      setState(() {
        if (api.code == 'not_found') {
          _phase = _Phase.notFound;
        } else {
          _error = _describe(api);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(ApiException e) {
    if (e.isNetworkError) {
      return 'You need a connection to link your membership.';
    }
    if (e.statusCode == 429 || e.code == 'too_many_attempts') {
      return 'Too many attempts, try again in an hour.';
    }
    return e.message;
  }

  /// "Not me": undo the link on the server, then show the form again.
  Future<void> _notMe() async {
    final found = _found;
    if (found == null) return;
    final repo = ref.read(membershipRepositoryProvider);
    final meSync = ref.read(meSyncProvider.notifier);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.unlink(found.clubId);
      meSync.markSynced();
      if (!mounted) return;
      setState(() {
        _found = null;
        _phase = _Phase.form;
      });
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (mounted) setState(() => _error = _describe(ApiException.from(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToForm() => setState(() {
    _phase = _Phase.form;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubConfigProvider);
    final account = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link your membership'),
        actions: [
          TextButton(
            onPressed: account == null
                ? null
                : () => ref
                      .read(accountsControllerProvider.notifier)
                      .remove(account.sub),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (_phase) {
                    _Phase.form => _buildForm(context),
                    _Phase.found => _buildFound(context, club),
                    _Phase.notFound => _buildNotFound(context, club),
                  },
                  const SizedBox(height: 24),
                  _JoinCard(club: club),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Link your England Athletics membership so the app knows who you are.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _urnController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'England Athletics URN',
              helperText:
                  'Your URN is on your England Athletics membership card, '
                  'and in the myAthletics portal.',
              helperMaxLines: 3,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your URN' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _dobController,
            enabled: !_busy,
            readOnly: true,
            onTap: _pickDob,
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            validator: (_) => _dob == null ? 'Choose your date of birth' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _findMe,
            child: _busy ? const _Spinner() : const Text('Find me'),
          ),
        ],
      ),
    );
  }

  Widget _buildFound(BuildContext context, ClubConfig club) {
    final theme = Theme.of(context);
    final m = _found!;
    final name = [m.firstName, m.lastName].whereType<String>().join(' ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We think we found you!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.isEmpty ? 'Member' : name,
              style: theme.textTheme.headlineSmall,
            ),
            if (m.category != null) Text(m.category!),
            Text(m.clubName),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : () => context.go('/'),
              child: const Text("That's me"),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _notMe,
              child: _busy ? const _Spinner() : const Text('Not me'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, ClubConfig club) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              "We couldn't find a member with those details",
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your URN and date of birth. If you joined the club '
              'recently, it can take up to a day for your membership to appear.',
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => openLink(context, ref, club.contactUrl),
                child: const Text('Still stuck? Contact us'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _backToForm,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends ConsumerWidget {
  const _JoinCard({required this.club});

  final ClubConfig club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          'Not a member yet?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        subtitle: Text(
          'Join ${club.name}',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        onTap: () => openLink(context, ref, club.joinUrl),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(strokeWidth: 2.5),
  );
}
