<?php

namespace App\Services;

use App\Models\ClubMember;
use App\Models\Notification;
use App\Models\Post;
use Illuminate\Support\Carbon;

/**
 * Builds the camelCase JSON shapes for posts, the inbox and preferences.
 */
class NotificationPresenter
{
    /** ISO8601 in UTC, or null. */
    public static function time($value): ?string
    {
        return $value ? Carbon::parse($value)->utc()->format('Y-m-d\TH:i:s.v\Z') : null;
    }

    /** Expects the author relation loaded. */
    public static function post(Post $post): array
    {
        return [
            'id' => $post->id,
            'title' => $post->title,
            'bodyMd' => $post->body_md,
            'priority' => $post->priority,
            'audience' => $post->audience,
            'publishedAt' => self::time($post->published_at),
            'pinnedUntil' => self::time($post->pinned_until),
            'author' => [
                'memberId' => $post->author_member_id,
                'displayName' => $post->author ? $post->author->display_name : null,
            ],
            'updatedAt' => self::time($post->updated_at),
            'deletedAt' => self::time($post->deleted_at),
        ];
    }

    public static function notification(Notification $notification): array
    {
        return [
            'id' => $notification->id,
            'category' => $notification->category,
            'title' => $notification->title,
            'body' => $notification->body,
            'data' => (object) ($notification->data ?? []),
            'createdAt' => self::time($notification->created_at),
            'readAt' => self::time($notification->read_at),
        ];
    }

    /**
     * @param array $enabled category => bool, the member's effective push setting
     */
    public static function categories(ClubMember $member, array $enabled): array
    {
        $items = [];

        foreach (NotificationCategories::visibleFor($member) as $key => $def) {
            $items[] = [
                'category' => $key,
                'label' => $def['label'],
                'description' => $def['description'],
                'pushEnabled' => $def['locked'] ? true : (bool) ($enabled[$key] ?? false),
                'locked' => $def['locked'],
            ];
        }

        return ['categories' => $items];
    }
}
