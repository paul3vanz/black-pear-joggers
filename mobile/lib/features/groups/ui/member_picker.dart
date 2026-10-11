import 'package:flutter/material.dart';

import '../data/member_dtos.dart';
import 'member_search.dart';

/// The result of [showMemberPicker]: a member, or null for "none". A dismissed
/// sheet returns null from the future itself (no [MemberPick]).
class MemberPick {
  const MemberPick(this.member);

  final MemberItem? member;
}

/// A bottom sheet with a search field over the club's members. With
/// [noneLabel] an extra first row (e.g. "No coordinator") returns a
/// [MemberPick] with no member.
Future<MemberPick?> showMemberPicker(
  BuildContext context, {
  required String title,
  String? noneLabel,
  Duration debounce = const Duration(milliseconds: 300),
}) => showModalBottomSheet<MemberPick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(title, style: Theme.of(sheet).textTheme.titleLarge),
            ),
            if (noneLabel != null)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(noneLabel),
                onTap: () => Navigator.of(sheet).pop(const MemberPick(null)),
              ),
            Expanded(
              child: MemberSearchList(
                debounce: debounce,
                onSelect: (m) => Navigator.of(sheet).pop(MemberPick(m)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
