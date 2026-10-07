<?php

namespace App\Services;

use App\Jobs\SendPushNotificationsJob;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\Notification;
use App\Models\NotificationPreference;

/**
 * The one way to tell members something.
 *
 *   app(NotificationService::class)->notifyMembers($club, $memberIds,
 *       NotificationCategories::CLUB_UPDATES, 'Title', 'Body', ['route' => '/updates/1']);
 *
 * Every member gets an inbox row (always). Whether they also get a push
 * depends on their preference for the category, the category default, locked
 * categories and $force (important posts). Eligible rows go to ONE queued job
 * on the `notifications` queue.
 */
class NotificationService
{
    const QUEUE = 'notifications';

    /**
     * @param iterable<string> $memberIds club_members.id values (other clubs' members are ignored)
     * @return Notification[] the inbox rows created
     */
    public function notifyMembers(
        Club $club,
        iterable $memberIds,
        string $category,
        string $title,
        string $body,
        array $data = [],
        bool $force = false
    ): array {
        $ids = [];
        foreach ($memberIds as $id) {
            $ids[$id] = $id;
        }

        if (!$ids || !NotificationCategories::exists($category)) {
            return [];
        }

        $members = ClubMember::where('club_id', $club->id)->whereIn('id', array_values($ids))->get();

        $prefs = NotificationPreference::where('club_id', $club->id)
            ->where('category', $category)
            ->whereIn('member_id', $members->pluck('id'))
            ->pluck('push_enabled', 'member_id');

        $created = [];
        $toPush = [];

        foreach ($members as $member) {
            $notification = Notification::create([
                'club_id' => $club->id,
                'member_id' => $member->id,
                'category' => $category,
                'title' => $title,
                'body' => $body,
                'data' => $data,
            ]);

            $created[] = $notification;

            if ($this->wantsPush($member, $category, $prefs->get($member->id), $force)) {
                $toPush[] = $notification->id;
            }
        }

        if ($toPush) {
            dispatch((new SendPushNotificationsJob($toPush))->onQueue(self::QUEUE));
        }

        return $created;
    }

    /**
     * @param bool|null $preference the member's saved choice, null when none
     */
    public function wantsPush(ClubMember $member, string $category, ?bool $preference, bool $force): bool
    {
        if ($force || NotificationCategories::isLocked($category)) {
            return true;
        }

        return $preference ?? NotificationCategories::defaultFor($category, $member);
    }
}
