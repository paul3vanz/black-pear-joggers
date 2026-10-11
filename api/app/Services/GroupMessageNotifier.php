<?php

namespace App\Services;

use App\Models\Club;
use App\Models\GroupMessage;
use App\Models\GroupThreadState;

/**
 * Tells a group's thread about a new message (Phase 6, D42).
 *
 * Audience: the thread's participants (leaders, going/maybe attendees, coordinator)
 * minus the author and anyone who muted the thread, active club members only. A
 * burst of messages is one inbox row per member (key `group_msg:<groupId>`, replaced
 * by the latest) and at most one push per 5 minutes. Muted members get no row at all.
 *
 * Safe to call from a request: any failure is logged and swallowed.
 */
class GroupMessageNotifier
{
    /** Minutes between pushes for the same thread. */
    const REPUSH_MINUTES = 5;

    public function newMessage(Club $club, ThreadAccess $thread, GroupMessage $message): void
    {
        $notifier = app(RunNotifier::class);

        $notifier->guard('group message', function () use ($club, $thread, $message, $notifier) {
            $muted = GroupThreadState::where('group_id', $thread->group->id)->where('muted', true)->pluck('member_id')->all();
            $ids = array_values(array_diff($thread->participantIds(), $muted));
            $ids = $notifier->activeIds($club, $ids, $message->member_id);

            if (!$ids) {
                return;
            }

            $author = $thread->people([$message->member_id])[$message->member_id]['name'];
            $body = RunText::clip((string) $message->body);

            $notifier->notifyByUnit(
                $club,
                $ids,
                NotificationCategories::GROUP_MESSAGES,
                $this->data($thread),
                ['dedupeKey' => 'group_msg:' . $thread->group->id, 'onDuplicate' => 'replace', 'repush' => self::REPUSH_MINUTES],
                function (?string $unit) use ($thread, $author, $body) {
                    return [$author . ' · ' . $thread->label($unit), $body];
                }
            );
        });
    }

    /** The data block of a message notification. */
    public function data(ThreadAccess $thread): array
    {
        $sessionId = $thread->session->id;
        $groupId = $thread->group->id;

        return [
            'route' => "/runs/$sessionId/groups/$groupId/chat",
            'sessionId' => $sessionId,
            'groupId' => $groupId,
        ];
    }
}
