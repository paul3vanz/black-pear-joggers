import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../membership/ui/membership_providers.dart';
import 'member_avatar.dart';
import 'member_providers.dart';

/// The Profile tab's entry to "My profile card" (D59): a prominent card with the
/// current photo (or initials) and a prompt until something has been added.
class MyProfileCardTile extends ConsumerWidget {
  const MyProfileCardTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(myCardProvider).value;
    final membership = ref.watch(activeMembershipProvider);
    final name = [
      membership?.firstName,
      if ((membership?.lastName ?? '').isNotEmpty)
        '${membership!.lastName![0]}.',
    ].whereType<String>().join(' ');
    final empty = card == null || card.isEmpty;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AvatarCircle(
          name: name,
          photoUrl: ref.watch(memberPhotoUrlProvider)(card?.photoPath),
          size: 48,
        ),
        title: const Text(
          'My profile card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          empty
              ? 'Add a photo and a few words about you'
              : 'Your photo, bio and goals',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/profile/card'),
      ),
    );
  }
}
