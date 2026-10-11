import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/posts_repository.dart';

/// `/updates/new`: committee/admin only (the FAB that opens it is hidden for
/// everyone else, and the server returns 403 anyway). Online-only for now: if the
/// request can't reach the server we say so and keep the draft on screen.
class ComposePostScreen extends ConsumerStatefulWidget {
  const ComposePostScreen({super.key});

  @override
  ConsumerState<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<ComposePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _preview = false;
  bool _important = false;
  bool _notify = true;
  String _audience = 'all';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_body.text.trim().isEmpty) {
      // The body field isn't mounted in preview mode, so check it here.
      setState(() {
        _preview = false;
        _error = 'Enter a message';
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(postsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await repo.create(
        clubId,
        title: _title.text.trim(),
        bodyMd: _body.text.trim(),
        priority: _important ? 'important' : 'normal',
        audience: _audience,
        notify: _notify,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Update posted')));
      if (mounted) router.pop();
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      final api = ApiException.from(e);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = api.isNetworkError
            ? "You're offline. Connect to the internet to post an update."
            : api.statusCode == 403
            ? "You don't have permission to post updates."
            : api.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New update'),
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 150,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Write')),
                  ButtonSegment(value: true, label: Text('Preview')),
                ],
                selected: {_preview},
                onSelectionChanged: (s) => setState(() => _preview = s.first),
              ),
              const SizedBox(height: 12),
              if (_preview)
                Container(
                  constraints: const BoxConstraints(minHeight: 160),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _body.text.trim().isEmpty
                      ? const Text('Nothing to preview yet.')
                      : MarkdownBody(data: _body.text),
                )
              else
                TextFormField(
                  controller: _body,
                  decoration: const InputDecoration(
                    labelText: 'Message (Markdown)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    helperText:
                        '**bold**, _italic_, [link](https://…), - lists',
                  ),
                  minLines: 6,
                  maxLines: 14,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a message'
                      : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(
                  labelText: 'Who can see it',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All members')),
                  DropdownMenuItem(
                    value: 'leaders',
                    child: Text('Leaders and committee'),
                  ),
                  DropdownMenuItem(
                    value: 'committee',
                    child: Text('Committee only'),
                  ),
                ],
                onChanged: (v) => setState(() => _audience = v ?? 'all'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Important'),
                subtitle: const Text(
                  'Highlighted, and sent even to people who muted club updates.',
                ),
                value: _important,
                onChanged: (v) => setState(() => _important = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send notification'),
                subtitle: const Text('Push to members in the audience.'),
                value: _notify,
                onChanged: (v) => setState(() => _notify = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
