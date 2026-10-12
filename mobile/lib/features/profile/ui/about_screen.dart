import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/club_config.dart';
import '../../../core/util/open_link.dart';
import 'profile_providers.dart';

/// Profile > About & privacy (`/profile/about`): app version, the privacy policy
/// and the account-deletion entry point that Google Play requires.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubConfigProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // "1.2.3 (4)" = version (build number). Null until the platform answers.
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('About & privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    club.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (version != null)
                    Text(
                      'Version $version',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LinkRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy policy',
              url: club.privacyPolicyUrl,
            ),
            _LinkRow(
              icon: Icons.language,
              label: 'Club website',
              url: club.website,
            ),
            // Same contact page the link flow offers when someone is stuck.
            _LinkRow(
              icon: Icons.mail_outline,
              label: 'Contact the committee',
              url: club.contactUrl,
            ),
            const SizedBox(height: 32),
            Text(
              'Danger zone',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(),
            ListTile(
              key: const ValueKey('delete-account-tile'),
              leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
              title: Text(
                'Delete my account',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Remove your profile and activity from this app.',
              ),
              onTap: () => context.push('/profile/about/delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends ConsumerWidget {
  const _LinkRow({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.open_in_new, size: 18),
    onTap: () => openLink(context, ref, url),
  );
}
