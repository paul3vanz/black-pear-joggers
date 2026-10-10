<?php

namespace App\Services;

use App\Jobs\SendPushNotificationsJob;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\NotificationPreference;
use Illuminate\Support\Carbon;

/**
 * The one way to tell members something.
 *
 *   app(NotificationService::class)->notifyMembers($club, $memberIds,
 *       NotificationCategories::CLUB_UPDATES, 'Title', 'Body', ['route' => '/updates/1']);
 *
 * Every member gets an inbox row (always). Whether they also get a push
 * depends on their preference for the category, the category default, locked
 * categories, $force (important posts) and the member's rolling 24 hour push
 * cap. Eligible rows go to ONE queued job on the `notifications` queue.
 *
 * $options (all optional, see mobile/docs/api-contract.md, Phase 5):
 *   dedupeKey    string (max 80). Same member + key = same news (see below).
 *   onDuplicate  'skip' (default) | 'replace'
 *   repush       minutes. With 'replace', push again only if the last push for
 *                the key is older than this. Default 0 for locked/forced, else 60.
 *
 * With a dedupeKey and an existing row for that member and key:
 *   identical title and body  -> nothing happens
 *   skip                      -> the existing row is left alone
 *   replace                   -> the row is updated in place (unread again, so the
 *                                app's `since` fetch re-delivers it) and maybe re-pushed
 *
 * Daily cap: pushes that are neither locked nor forced count towards
 * member_preferences.push_daily_cap (null = 6, 0 = no limit) per rolling 24
 * hours, measured by notifications.push_requested_at. Over the cap the inbox
 * row is still written, only the push is dropped.
 */
class NotificationService
{
    const QUEUE = 'notifications';

    /** Pushes per rolling 24 hours when the member has not chosen a number. */
    const DEFAULT_DAILY_CAP = 6;

    const DEFAULT_REPUSH_MINUTES = 60;

    const DEDUPE_MAX = 80;

    /** The random token that lets a notification button answer without signing in. */
    public static function newActionToken(): string
    {
        return bin2hex(random_bytes(16));
    }

    /**
     * @param iterable<string> $memberIds club_members.id values (other clubs' members are ignored)
     * @return Notification[] the inbox rows created or replaced
     */
    public function notifyMembers(
        Club $club,
        iterable $memberIds,
        string $category,
        string $title,
        string $body,
        array $data = [],
        bool $force = false,
        array $options = []
    ): array {
        $ids = [];
        foreach ($memberIds as $id) {
            $ids[$id] = $id;
        }

        if (!$ids || !NotificationCategories::exists($category)) {
            return [];
        }

        $members = ClubMember::where('club_id', $club->id)->whereIn('id', array_values($ids))->get();
        $memberKeys = $members->pluck('id');

        $prefs = NotificationPreference::where('club_id', $club->id)
            ->where('category', $category)
            ->whereIn('member_id', $memberKeys)
            ->pluck('push_enabled', 'member_id');

        $dedupeKey = isset($options['dedupeKey']) && $options['dedupeKey'] !== ''
            ? substr((string) $options['dedupeKey'], 0, self::DEDUPE_MAX)
            : null;
        $replace = ($options['onDuplicate'] ?? 'skip') === 'replace';
        $uncapped = $force || NotificationCategories::isLocked($category);
        $repush = (int) ($options['repush'] ?? ($uncapped ? 0 : self::DEFAULT_REPUSH_MINUTES));

        $existing = [];
        if ($dedupeKey !== null) {
            foreach (Notification::where('club_id', $club->id)
                ->where('dedupe_key', $dedupeKey)
                ->whereIn('member_id', $memberKeys)
                ->orderBy('created_at')->get() as $row) {
                $existing[$row->member_id] = $row;
            }
        }

        $caps = $counts = [];
        if (!$uncapped) {
            $caps = $this->dailyCaps($club, $memberKeys->all());
            $counts = $this->recentPushCounts($club, $memberKeys->all());
        }

        $now = Carbon::now();
        $created = [];
        $toPush = [];

        foreach ($members as $member) {
            $row = $existing[$member->id] ?? null;
            $repushing = false;

            if ($row) {
                if ($row->title === $title && $row->body === $body) {
                    continue;
                }

                if (!$replace) {
                    continue;
                }

                $lastPush = $this->lastPush($row);
                $repushing = $repush <= 0 || $lastPush === null || $lastPush->lte($now->copy()->subMinutes($repush));

                $row->fill(['title' => $title, 'body' => $body, 'data' => $data, 'read_at' => null]);
                $row->updated_at = $now; // bumped even if nothing else differs, so `since` re-sends it
            } else {
                $row = new Notification([
                    'club_id' => $club->id,
                    'member_id' => $member->id,
                    'category' => $category,
                    'title' => $title,
                    'body' => $body,
                    'data' => $data,
                    'dedupe_key' => $dedupeKey,
                ]);
            }

            $pushes = (!$row->exists || $repushing) && $this->wantsPush($member, $category, $prefs->get($member->id), $force);

            if ($pushes && !$uncapped) {
                $already = $counts[$member->id] ?? 0;

                // A row being re-pushed is already inside the window once.
                if ($row->exists && $row->push_requested_at && $row->push_requested_at->gt($now->copy()->subDay())) {
                    $already--;
                }

                $cap = self::capFrom($caps[$member->id] ?? null);

                if ($cap !== 0 && $already >= $cap) {
                    $pushes = false;
                }
            }

            if ($pushes) {
                if (!$uncapped) {
                    $row->push_requested_at = $now;
                    $counts[$member->id] = ($counts[$member->id] ?? 0) + 1;
                }

                $row->pushed_at = null; // let the job send a replaced row again
            }

            $row->save();
            $created[] = $row;

            if ($pushes) {
                $toPush[] = $row->id;
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

    /** The daily cap in effect for a saved value: null = the default, 0 = no limit. */
    public static function capFrom($saved): int
    {
        return $saved === null ? self::DEFAULT_DAILY_CAP : (int) $saved;
    }

    /** The most recent time a push was queued or delivered for the row. */
    private function lastPush(Notification $row): ?Carbon
    {
        $times = array_filter([$row->push_requested_at, $row->pushed_at]);

        return $times ? Carbon::instance(max($times)) : null;
    }

    /** @return array<string, int|null> member id => saved push_daily_cap */
    private function dailyCaps(Club $club, array $memberIds): array
    {
        return MemberPreference::where('club_id', $club->id)
            ->whereIn('member_id', $memberIds)
            ->pluck('push_daily_cap', 'member_id')
            ->all();
    }

    /** @return array<string, int> member id => capped pushes requested in the last 24 hours */
    private function recentPushCounts(Club $club, array $memberIds): array
    {
        return Notification::where('club_id', $club->id)
            ->whereIn('member_id', $memberIds)
            ->where('push_requested_at', '>', Carbon::now()->subDay())
            ->selectRaw('member_id, count(*) as pushes')
            ->groupBy('member_id')
            ->pluck('pushes', 'member_id')
            ->map(function ($n) {
                return (int) $n;
            })
            ->all();
    }
}
