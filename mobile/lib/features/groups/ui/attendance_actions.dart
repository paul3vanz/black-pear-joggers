import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/pace_spec.dart';
import '../data/attendance_repository.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// The caller's current response to a run: the status, group and per-run pace,
/// from the local attendance row (which includes unsent changes) or else the
/// session `summary`.
typedef MyResponse = ({
  String? status,
  String? groupId,
  PaceSpec pace,
  bool pending,
});

MyResponse myResponse(WidgetRef ref, String sessionId) {
  final row = ref.watch(myAttendanceProvider(sessionId)).value;
  final summary = ref.watch(sessionSummaryProvider(sessionId)).value;
  final status = row?.status ?? summary?.myStatus;
  return (
    status: status,
    groupId: status == 'not_going'
        ? null
        : (row?.groupId ?? summary?.myGroupId),
    pace: row == null ? const NoPace() : row.pace,
    pending: row?.pending ?? false,
  );
}

/// Sets the caller's response to [session] (optimistic, D23) and tells them
/// what happened: a SnackBar for "queued" (offline) and for a rejection (409
/// cancelled/finished). Without [paceOverride] the existing per-run pace is
/// kept, because the server clears it when it is left out; pass [NoPace] to
/// clear it. Returns the outcome, or null when the session expired.
Future<AttendanceOutcome?> respondToRun(
  BuildContext context,
  WidgetRef ref, {
  required Session session,
  required String status,
  String? groupId,
  PaceSpec? paceOverride,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final sub = ref.read(activeSubProvider);
  final handleExpiry = ref.read(sessionExpiryHandlerProvider);
  final repo = ref.read(attendanceRepositoryProvider);
  final current = ref.read(myAttendanceProvider(session.id)).value;
  final pace = paceOverride ?? current?.pace ?? const NoPace();
  try {
    final result = await repo.setAttendance(
      session.id,
      status,
      groupId: groupId,
      paceOverride: pace,
    );
    switch (result.outcome) {
      case AttendanceOutcome.queued:
        messenger.showSnackBar(
          const SnackBar(content: Text("Saved, will sync when you're online")),
        );
      case AttendanceOutcome.rejected:
        messenger.showSnackBar(
          SnackBar(content: Text(groupErrorMessage(result.error!))),
        );
      case AttendanceOutcome.saved:
        if (context.mounted) ref.invalidate(planLoadProvider(session.id));
    }
    return result.outcome;
  } on Object catch (e) {
    if (sub != null && await handleExpiry(sub, e)) return null;
    messenger.showSnackBar(SnackBar(content: Text(groupErrorMessage(e))));
    return AttendanceOutcome.rejected;
  }
}
