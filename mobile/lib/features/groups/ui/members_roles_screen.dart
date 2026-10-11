import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../membership/data/membership_repository.dart';
import '../data/member_dtos.dart';
import 'group_access.dart';
import 'member_search.dart';
import 'roles_sheet.dart';

/// `/profile/members`: search the club's members and change their roles
/// (committee tools). Committee and admin can toggle the `leader` badge; only
/// an admin can grant or remove `committee` and `admin`. Online-only.
class MembersRolesScreen extends ConsumerStatefulWidget {
  const MembersRolesScreen({super.key});

  @override
  ConsumerState<MembersRolesScreen> createState() => _MembersRolesScreenState();
}

class _MembersRolesScreenState extends ConsumerState<MembersRolesScreen> {
  final _search = GlobalKey<MemberSearchListState>();

  Future<void> _open(MemberItem member) async {
    final saved = await showRolesSheet(
      context,
      ref,
      member: member,
      isSelf: member.memberId == ref.read(myMemberIdProvider),
      isAdmin: ref.read(isAdminProvider),
    );
    if (saved == null || !mounted) return;
    _search.currentState?.replace(saved);
    if (saved.memberId == ref.read(myMemberIdProvider)) {
      // Our own roles changed: pick up the new set for the screens we gate.
      try {
        await ref.read(membershipRepositoryProvider).refreshMe();
      } on Object {
        // Offline: the next app start refreshes it.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the membership (and so our roles) is loaded when a row is
    // tapped; `_open` reads them.
    ref.watch(isAdminProvider);
    ref.watch(myMemberIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Members and roles')),
      body: SafeArea(
        child: MemberSearchList(
          key: _search,
          onSelect: (m) => unawaited(_open(m)),
        ),
      ),
    );
  }
}
