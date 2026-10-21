<?php

namespace App\Services;

use App\Models\Club;
use App\Models\Notification;
use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostThreadState;
use Illuminate\Support\Carbon;

/**
 * Tells people about a new comment on a club update (D126).
 *
 * Audience: the committee, everyone who has commented and everyone who has
 * opened the thread (PostThreadAccess::participantIds), minus the author and
 * anyone who muted it, active club members only. Sent as `club_updates` with the
 * route of the comments. A burst is one inbox row per member (key
 * `post_comment:<postId>`, replaced by the latest) and at most one push per
 * 5 minutes. Muted members get no row at all.
 *
 * Safe to call from a request: any failure is logged and swallowed.
 */
class PostThreadNotifier
{
    /** Minutes between pushes for the same thread. */
    const REPUSH_MINUTES = 5;

    public function newComment(Club $club, PostThreadAccess $thread, PostComment $comment): void
    {
        $notifier = app(RunNotifier::class);

        $notifier->guard('post comment', function () use ($club, $thread, $comment) {
            $muted = PostThreadState::where('post_id', $thread->post->id)->where('muted', true)->pluck('member_id')->all();
            $ids = array_values(array_diff($thread->participantIds(), $muted));
            $ids = app(RunNotifier::class)->activeIds($club, $ids, $comment->member_id);

            if (!$ids) {
                return;
            }

            $who = $thread->people([$comment->member_id])[$comment->member_id];
            $title = ($who['role'] === ThreadAccess::ROLE_COMMITTEE ? $who['name'] . ' (committee)' : $who['name']) . ' · ' . $thread->post->title;

            app(NotificationService::class)->notifyMembers(
                $club,
                $ids,
                NotificationCategories::CLUB_UPDATES,
                RunText::clip($title, 80),
                RunText::clip((string) $comment->body),
                $this->data($thread->post),
                false,
                ['dedupeKey' => 'post_comment:' . $thread->post->id, 'onDuplicate' => 'replace', 'repush' => self::REPUSH_MINUTES]
            );
        });
    }

    /** The data block of a comment notification. */
    public function data(Post $post): array
    {
        return [
            'route' => '/updates/' . $post->id . '/comments',
            'postId' => $post->id,
            'groupId' => PostThreadAccess::threadId($post),
        ];
    }

    /** Marks a member's inbox row for this thread read. */
    public function markInboxRead(string $memberId, Post $post, Carbon $now): void
    {
        Notification::where('member_id', $memberId)
            ->where('dedupe_key', 'post_comment:' . $post->id)
            ->whereNull('read_at')
            ->update(['read_at' => $now, 'updated_at' => $now]);
    }
}
